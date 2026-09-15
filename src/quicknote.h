#ifndef QUICKNOTE_H
#define QUICKNOTE_H

#include <QObject>
#include <QRandomGenerator>
#include <QString>
#include <QProcess>
#include <QList>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class QuickNote : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(int BufferIndex READ BufferIndex NOTIFY BufferIndexChanged)
    Q_PROPERTY(int MaxBuffers READ MaxBuffers CONSTANT)
    Q_PROPERTY(QString lastError READ lastError NOTIFY errorOccurred)

public:
    explicit QuickNote(QObject* parent = nullptr);
    ~QuickNote();

    int BufferIndex() const;
    int MaxBuffers() const { return MAX_BUFFERS; }
    QString lastError() const { return m_lastError; }

    Q_INVOKABLE QString GetBufferTextAt(int index) const;
    Q_INVOKABLE void SetBufferTextAt(int index, const QString &newText);
    Q_INVOKABLE bool SaveBufferToFile(int index, const QString &path);
    Q_INVOKABLE void RunBufferInTerminal(int index) const;
    Q_INVOKABLE void RunStringInTerminal(const QString &text) const;

signals:
    void BufferIndexChanged(int newIndex, const QString &newText);
    void errorOccurred(const QString &errorMessage);

private slots:
    void SaveNote();

public slots:
    void NextBuffer();

private:
    static const int MAX_BUFFERS = 7;

    int m_currentBufferIndex;
    QList<QString> m_buffers;
    QList<bool> m_dirtyBuffers;
    int m_dirFd;
    QString m_lastError;
    void setError(const QString &msg) { m_lastError = msg; emit errorOccurred(msg); }
    QTimer m_saveTimer;

    void LoadNote();
};

#endif
