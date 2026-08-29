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

public:
    explicit QuickNote(QObject* parent = nullptr);
    ~QuickNote();

    int BufferIndex() const;
    int MaxBuffers() const { return MAX_BUFFERS; }

    Q_INVOKABLE QString GetBufferTextAt(int index) const;
    Q_INVOKABLE void SetBufferTextAt(int index, const QString &newText);
    Q_INVOKABLE void SaveBufferToFile(int index, const QString &path) const;
    Q_INVOKABLE void RunBufferInTerminal(int index) const;
    Q_INVOKABLE void RunStringInTerminal(const QString &text) const;

signals:
    void BufferIndexChanged(int newIndex, const QString &newText);

private slots:
    void SaveNote();

public slots:
    void NextBuffer();

private:
    static const int MAX_BUFFERS = 7;

    int m_currentBufferIndex;
    QList<QString> m_buffers;
    int m_dirFd;
    QTimer m_saveTimer;

    void LoadNote();
};

#endif
