#include "quicknote.h"
#include <QFile>
#include <QTextStream>
#include <QStandardPaths>
#include <QDir>

QuickNote::QuickNote(QObject* parent) : QObject(parent){
    QString stateLocation = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(stateLocation);
    dir.mkpath("quicknote");

    m_filePath = dir.absoluteFilePath("quicknote/note.txt");

    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(500);
    connect(&m_saveTimer, &QTimer::timeout, this, &QuickNote::SaveNote);

    LoadNote();
}

QString QuickNote::NoteText() const {return m_noteText;}

void QuickNote::SetNoteText(const QString &noteText){
    if(m_noteText == noteText) return;

    m_noteText = noteText;
    emit NoteTextChanged();

    m_saveTimer.start();
}

void QuickNote::LoadNote(){
    QFile file(m_filePath);
    if(file.open(QIODevice::ReadOnly | QIODevice::Text)){
        m_noteText = QString::fromUtf8(file.readAll());
    }
}

void QuickNote::SaveNote(){
    QFile file(m_filePath);
    if(file.open(QIODevice::WriteOnly | QIODevice::Text)){
        file.write(m_noteText.toUtf8());
    }
}
