#include "quicknote.h"
#include <QFile>
#include <QStandardPaths>
#include <QDir>

QuickNote::QuickNote(QObject* parent) : QObject(parent), m_currentBufferIndex(0){
    QString stateLocation = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(stateLocation);
    dir.mkpath("quicknote");
    m_directoryPath = dir.absoluteFilePath("quicknote");

    for(int i = 0; i < MAX_BUFFERS; i++){
        m_buffers.append("");
    }

    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(500);
    connect(&m_saveTimer, &QTimer::timeout, this, &QuickNote::SaveNote);

    LoadNote();
}

int QuickNote::BufferIndex() const {return m_currentBufferIndex;}

void QuickNote::NextBuffer(){
    m_currentBufferIndex = (m_currentBufferIndex + 1) % MAX_BUFFERS;

    emit BufferIndexChanged(m_currentBufferIndex, m_buffers[m_currentBufferIndex]);
}

void QuickNote::LoadNote(){
    for(int i = 0; i < MAX_BUFFERS; i++){
        QString path = m_directoryPath + QString("/note_%1.txt").arg(i);
        QFile file(path);
        if(file.open(QIODevice::ReadOnly | QIODevice::Text)){
            m_buffers[i] = QString::fromUtf8(file.readAll());
        }
    }
}

void QuickNote::SaveNote(){
    QDir dir(m_directoryPath);
    for(int i = 0; i < MAX_BUFFERS; i++){
        QString path = dir.filePath("note_" + QString::number(i) + ".txt");
        QFile file(path);
        if(file.open(QIODevice::WriteOnly | QIODevice::Text)){
            file.write(m_buffers[i].toUtf8());
        }
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
    QString filePath = "/tmp/quicknote_run.sh";

    QFile file(filePath);
    if(file.open(QIODevice::WriteOnly | QIODevice::Text)){
        QTextStream out(&file);
        out << text;
        file.close();

        file.setPermissions(QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner);

        QString cmd;
        if(text.startsWith("#!")){
            cmd = filePath + "; exec bash";
        }
        else {
            cmd = "source ~/.bashrc 2>/dev/null; source " + filePath + "; exec bash";
        }

        QProcess::startDetached(
            "xdg-terminal-exec", 
            {"bash", "-c", cmd}
        );
    }
}

void QuickNote::SaveBufferToFile(int index, const QString &path) const {
    if(index >= 0 && index < MAX_BUFFERS){
        QString cleanPath = path;
        if(cleanPath.startsWith("~/")){
            cleanPath.replace(0, 2, QDir::homePath() + "/");
        }
        QFile file(cleanPath);
        if(file.open(QIODevice::WriteOnly | QIODevice::Text)){
            QTextStream out(&file);
            out << m_buffers[index];
            file.close();
        }
    }
}
