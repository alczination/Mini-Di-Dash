#pragma once

#include <QObject>
#include <QThread>
#include <QString>
#include <atomic>

class GearWorker : public QThread {
    Q_OBJECT
public:
    explicit GearWorker(int gear1Pin = 6, int gear2Pin = 5, QObject *parent = nullptr);
    ~GearWorker() override;
    void stop();

signals:
    void gearChanged(const QString &gear);

protected:
    void run() override;

private:
    int m_gear1Pin;
    int m_gear2Pin;
    std::atomic<bool> m_running{true};
};

class GearBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentGear READ currentGear NOTIFY currentGearChanged)

public:
    explicit GearBackend(QObject *parent = nullptr);
    ~GearBackend() override;

    QString currentGear() const { return m_currentGear; }

signals:
    void currentGearChanged();

private slots:
    void onGearUpdated(const QString &gear);

private:
    QString m_currentGear = "N";
    GearWorker *m_worker = nullptr;
};
