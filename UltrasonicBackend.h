#pragma once

#include <QObject>
#include <QThread>
#include <atomic>

class UltrasonicWorker : public QThread {
    Q_OBJECT

public:
    explicit UltrasonicWorker(int trigPin = 4, int echoPin = 17, QObject *parent = nullptr);
    ~UltrasonicWorker() override;
    void stop();

signals:
    void distanceUpdated(double distance);

protected:
    void run() override;

private:
    int m_trigPin;
    int m_echoPin;
    std::atomic<bool> m_running{true};
};

class UltrasonicBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(double distance READ distance NOTIFY distanceChanged)

public:
    explicit UltrasonicBackend(QObject *parent = nullptr);
    ~UltrasonicBackend() override;

    double distance() const { return m_distance; }

signals:
    void distanceChanged();

private slots:
    void onDistanceUpdated(double dist);

private:
    double m_distance = 200.0;
    UltrasonicWorker *m_worker = nullptr;
};
