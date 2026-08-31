#include "quicknote.h"
#include <QFile>
#include <QTemporaryFile>
#include <QStandardPaths>
#include <QDir>
#include <QProcess>
#include <QFileInfo>
#include <QRandomGenerator>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <cerrno>

static int openWalkDir(const QByteArray &path) {
    if (path.isEmpty() || path[0] != '/') return -1;
    
    QList<QByteArray> parts = path.split('/');
    int currentFd = ::open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC);
    if (currentFd < 0) return -1;
    
    for (int i = 1; i < parts.size(); ++i) {
        if (parts[i].isEmpty()) continue;
        int nextFd = ::openat(currentFd, parts[i].constData(), O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
        if (nextFd < 0) {
            ::close(currentFd);
            return -1;
        }
        ::close(currentFd);
        currentFd = nextFd;
    }
    return currentFd;
}

static int openSafeDir(const QByteArray &path) {
    if (path.isEmpty() || path[0] != '/') return -1;
    
    QList<QByteArray> parts = path.split('/');
    int currentFd = ::open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC);
    if (currentFd < 0) return -1;
    
    for (int i = 1; i < parts.size(); ++i) {
        if (parts[i].isEmpty()) continue;
        
        int nextFd = ::openat(currentFd, parts[i].constData(), O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
        if (nextFd < 0) {
            if (errno == ENOENT) {
                if (::mkdirat(currentFd, parts[i].constData(), 0700) != 0 && errno != EEXIST) {
                    ::close(currentFd);
                    return -1;
                }
                nextFd = ::openat(currentFd, parts[i].constData(), O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
            }
            if (nextFd < 0) {
                ::close(currentFd);
                return -1;
            }
        }
        ::close(currentFd);
        currentFd = nextFd;
        
        struct stat st;
        if(::fstat(currentFd, &st) != 0 || !S_ISDIR(st.st_mode)){
            ::close(currentFd);
            return -1;
        }
    }
    
    struct stat st;
    if(::fstat(currentFd, &st) != 0 || st.st_uid != ::getuid()){
        ::close(currentFd);
        return -1;
    }
    
    if((st.st_mode & 07777) != 0700){
        if(::fchmod(currentFd, 0700) != 0){
            ::close(currentFd);
            return -1;
        }
    }
    
    return currentFd;
}

static bool secureSave(int dirFd, const QByteArray &filename, const QByteArray &data){
    QByteArray tmp = "." + filename + "." + QByteArray::number(QRandomGenerator::global()->generate(), 16) + ".tmp";

    int fd = ::openat(dirFd, tmp.constData(), O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0600);
    if(fd < 0) return false;

    struct stat st_before;
    if(::fstat(fd, &st_before) != 0){
        ::close(fd);
        ::unlinkat(dirFd, tmp.constData(), 0);
        return false;
    }

    const char *p = data.constData();
    qint64 left = data.size();
    while(left > 0){
        ssize_t n = ::write(fd, p, static_cast<size_t>(left));
        if(n < 0){
            if(errno == EINTR) continue;
            ::close(fd);
            ::unlinkat(dirFd, tmp.constData(), 0);
            return false;
        }
        p += n;
        left -= n;
    }

    if(::fsync(fd) != 0){
        ::close(fd);
        ::unlinkat(dirFd, tmp.constData(), 0);
        return false;
    }

    if(::renameat(dirFd, tmp.constData(), dirFd, filename.constData()) != 0){
        ::close(fd);
        ::unlinkat(dirFd, tmp.constData(), 0);
        return false;
    }

    struct stat st_after;
    if(::fstatat(dirFd, filename.constData(), &st_after, AT_SYMLINK_NOFOLLOW) != 0 ||
       st_before.st_ino != st_after.st_ino || st_before.st_dev != st_after.st_dev ||
       !S_ISREG(st_after.st_mode) || st_after.st_uid != ::getuid() || (st_after.st_mode & 07777) != 0600){
        ::close(fd);
        ::unlinkat(dirFd, filename.constData(), 0);
        return false;
    }

    ::close(fd);
    return true;
}

static QByteArray secureRead(int dirFd, const QByteArray &filename){
    int fd = ::openat(dirFd, filename.constData(), O_RDONLY | O_NOFOLLOW | O_CLOEXEC);
    if(fd < 0) return {};

    struct stat st;
    if(::fstat(fd, &st) != 0 || !S_ISREG(st.st_mode) || st.st_uid != ::getuid()){
        ::close(fd);
        return {};
    }

    if(st.st_size > 10 * 1024 * 1024) { 
        ::close(fd);
        return {};
    }

    QByteArray buf(static_cast<int>(st.st_size), Qt::Uninitialized);
    char *p = buf.data();
    qint64 left = st.st_size;
    while(left > 0){
        ssize_t n = ::read(fd, p, static_cast<size_t>(left));
        if(n < 0){
            if(errno == EINTR) continue;
            ::close(fd);
            return {};
        }
        if(n == 0) break;
        p += n;
        left -= n;
    }
    ::close(fd);
    buf.truncate(static_cast<int>(st.st_size - left));
    return buf;
}

static bool secureSaveToPath(const QString &filePath, const QByteArray &data){
    QFileInfo fi(filePath);
    QByteArray parentPath = fi.absolutePath().toUtf8();
    QByteArray fileName = fi.fileName().toUtf8();
    QByteArray tmp = "." + fileName + "." + QByteArray::number(QRandomGenerator::global()->generate(), 16) + ".tmp";

    int parentFd = openWalkDir(parentPath);
    if(parentFd < 0) return false;

    int fd = ::openat(parentFd, tmp.constData(), O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0600);
    if(fd < 0){
        ::close(parentFd);
        return false;
    }

    struct stat st_before;
    if(::fstat(fd, &st_before) != 0){
        ::close(fd);
        ::unlinkat(parentFd, tmp.constData(), 0);
        ::close(parentFd);
        return false;
    }

    const char *p = data.constData();
    qint64 left = data.size();
    while(left > 0){
        ssize_t n = ::write(fd, p, static_cast<size_t>(left));
        if(n < 0){
            if(errno == EINTR) continue;
            ::close(fd);
            ::unlinkat(parentFd, tmp.constData(), 0);
            ::close(parentFd);
            return false;
        }
        p += n;
        left -= n;
    }

    if(::fsync(fd) != 0){
        ::close(fd);
        ::unlinkat(parentFd, tmp.constData(), 0);
        ::close(parentFd);
        return false;
    }

    if(::renameat(parentFd, tmp.constData(), parentFd, fileName.constData()) != 0){
        ::close(fd);
        ::unlinkat(parentFd, tmp.constData(), 0);
        ::close(parentFd);
        return false;
    }

    struct stat st_after;
    if(::fstatat(parentFd, fileName.constData(), &st_after, AT_SYMLINK_NOFOLLOW) != 0 ||
       st_before.st_ino != st_after.st_ino || st_before.st_dev != st_after.st_dev ||
       !S_ISREG(st_after.st_mode) || st_after.st_uid != ::getuid()){
        ::close(fd);
        ::unlinkat(parentFd, fileName.constData(), 0);
        ::close(parentFd);
        return false;
    }

    ::close(fd);
    ::close(parentFd);
    return true;
}

QuickNote::QuickNote(QObject* parent) : QObject(parent), m_currentBufferIndex(0), m_dirFd(-1){
    QString stateLocation = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);

    m_dirFd = openSafeDir((stateLocation + "/quicknote").toUtf8());

    for(int i = 0; i < MAX_BUFFERS; i++){
        m_buffers.append("");
    }

    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(500);
    connect(&m_saveTimer, &QTimer::timeout, this, &QuickNote::SaveNote);

    LoadNote();
}

QuickNote::~QuickNote(){
    if(m_dirFd >= 0) ::close(m_dirFd);
}

int QuickNote::BufferIndex() const {return m_currentBufferIndex;}

void QuickNote::NextBuffer(){
    m_currentBufferIndex = (m_currentBufferIndex + 1) % MAX_BUFFERS;

    emit BufferIndexChanged(m_currentBufferIndex, m_buffers[m_currentBufferIndex]);
}

void QuickNote::LoadNote(){
    if(m_dirFd < 0) return;

    for(int i = 0; i < MAX_BUFFERS; i++){
        QByteArray filename = QString("note_%1.txt").arg(i).toUtf8();
        QByteArray data = secureRead(m_dirFd, filename);
        if(!data.isEmpty()){
            m_buffers[i] = QString::fromUtf8(data);
        }
    }
}

void QuickNote::SaveNote(){
    if(m_dirFd < 0) return;

    for(int i = 0; i < MAX_BUFFERS; i++){
        QByteArray filename = QString("note_%1.txt").arg(i).toUtf8();
        secureSave(m_dirFd, filename, m_buffers[i].toUtf8());
    }
}

QString QuickNote::GetBufferTextAt(int index) const {
    if(index >= 0 && index < MAX_BUFFERS){
        return m_buffers[index];
    }
    return QString();
}

void QuickNote::SetBufferTextAt(int index, const QString &newText){
    if(index >= 0 && index < MAX_BUFFERS){
        if(m_buffers[index] != newText){
            m_buffers[index] = newText;
            m_saveTimer.start(500);
        }
    }
}

void QuickNote::RunBufferInTerminal(int index) const {
    if(index >= 0 && index < MAX_BUFFERS){
        RunStringInTerminal(m_buffers[index]);
    }
}

void QuickNote::RunStringInTerminal(const QString &text) const {
    QString runtimePath = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    if(runtimePath.isEmpty()){
        runtimePath = QDir::tempPath() + "/quicknote_" + QString::number(::getuid());
    } else {
        runtimePath += "/quicknote_run";
    }

    int runDirFd = openSafeDir(runtimePath.toUtf8());
    if (runDirFd < 0) return;

    QByteArray scriptName = QByteArray("run_") + QByteArray::number(QRandomGenerator::global()->generate(), 16) + ".sh";
    int fd = ::openat(runDirFd, scriptName.constData(), O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0700);
    if (fd < 0) {
        ::close(runDirFd);
        return;
    }

    QByteArray data = text.toUtf8();
    const char *p = data.constData();
    qint64 left = data.size();
    while(left > 0){
        ssize_t n = ::write(fd, p, static_cast<size_t>(left));
        if(n < 0){
            if(errno == EINTR) continue;
            ::close(fd);
            ::unlinkat(runDirFd, scriptName.constData(), 0);
            ::close(runDirFd);
            return;
        }
        p += n;
        left -= n;
    }

    if(::fsync(fd) != 0){
        ::close(fd);
        ::unlinkat(runDirFd, scriptName.constData(), 0);
        ::close(runDirFd);
        return;
    }

    struct stat st_before;
    if(::fstat(fd, &st_before) != 0){
        ::close(fd);
        ::unlinkat(runDirFd, scriptName.constData(), 0);
        ::close(runDirFd);
        return;
    }

    struct stat st_after;
    if(::fstatat(runDirFd, scriptName.constData(), &st_after, AT_SYMLINK_NOFOLLOW) != 0 ||
       st_before.st_ino != st_after.st_ino || st_before.st_dev != st_after.st_dev ||
       !S_ISREG(st_after.st_mode) || st_after.st_uid != ::getuid() || (st_after.st_mode & 07777) != 0700){
        ::close(fd);
        ::unlinkat(runDirFd, scriptName.constData(), 0);
        ::close(runDirFd);
        return;
    }

    QString fullPath = runtimePath + "/" + scriptName;

    QString cmd;
    if(text.startsWith("#!")){
        cmd = "\"$1\"; rm -f \"$1\"; exec bash";
    }
    else {
        cmd = "source ~/.bashrc 2>/dev/null; source \"$1\"; rm -f \"$1\"; exec bash";
    }

    QProcess::startDetached(
        "xdg-terminal-exec", 
        {"bash", "-c", cmd, "bash", fullPath}
    );

    ::close(fd);
    ::close(runDirFd);
}

void QuickNote::SaveBufferToFile(int index, const QString &path) const {
    if(index < 0 || index >= MAX_BUFFERS) return;

    QString cleanPath = path;
    if(cleanPath.startsWith("~/")){
        cleanPath.replace(0, 2, QDir::homePath() + "/");
    }

    secureSaveToPath(cleanPath, m_buffers[index].toUtf8());
}
