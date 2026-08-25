#ifndef QUICKNOTE_H
#define QUICKNOTE_H

#include <QObject>
#include <QString>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class QuickNote : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QString NoteText READ NoteText WRITE SetNoteText NOTIFY NoteTextChanged)

public:
    explicit QuickNote(QObject* parent = nullptr);

    QString NoteText() const;

    void SetNoteText(const QString &newText);

signals:
    void NoteTextChanged();

private slots:
    void SaveNote();

private:
    QString m_noteText;
    QString m_filePath;
    QTimer m_saveTimer;

    void LoadNote();
};

#endif
