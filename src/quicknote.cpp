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

QString QuickNote::NoteText() const {return m_buffers[m_currentBufferIndex];}

int QuickNote::BufferIndex() const {return m_currentBufferIndex;}

void QuickNote::SetNoteText(const QString &noteText){
    if(m_buffers[m_currentBufferIndex] == noteText) return;
    m_buffers[m_currentBufferIndex] = noteText;

    emit NoteTextChanged();
    m_saveTimer.start();
}

void QuickNote::NextBuffer(){
    m_currentBufferIndex = (m_currentBufferIndex + 1) % MAX_BUFFERS;

    emit NoteTextChanged();
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
    QString path = m_directoryPath + QString("/note_%1.txt").arg(m_currentBufferIndex);
    QFile file(path);
    if(file.open(QIODevice::WriteOnly | QIODevice::Text)){
        file.write(m_buffers[m_currentBufferIndex].toUtf8());
    }
}
