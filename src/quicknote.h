#ifndef QUICKNOTE_H
#define QUICKNOTE_H

#include <QObject>
#include <QString>
#include <QList>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class QuickNote : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QString NoteText READ NoteText WRITE SetNoteText NOTIFY NoteTextChanged)
    Q_PROPERTY(int BufferIndex READ BufferIndex NOTIFY BufferIndexChanged)

public:
    explicit QuickNote(QObject* parent = nullptr);

    QString NoteText() const;
    int BufferIndex() const;
    void SetNoteText(const QString &newText);

    Q_INVOKABLE QString GetNoteText() const { return m_buffers[m_currentBufferIndex]; }
    Q_INVOKABLE QString GetBufferTextAt(int index) const;
    Q_INVOKABLE void SetBufferTextAt(int index, const QString &newText);

signals:
    void NoteTextChanged();
    void BufferIndexChanged(int newIndex, const QString &newText);

private slots:
    void SaveNote();

public slots:
    void NextBuffer();

private:
    static const int MAX_BUFFERS = 7;

    int m_currentBufferIndex;
    QList<QString> m_buffers;
    QString m_directoryPath;
    QTimer m_saveTimer;

    void LoadNote();
};

#endif
