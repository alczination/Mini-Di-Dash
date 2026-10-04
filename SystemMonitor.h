#pragma once
#include <QObject>
#include <QTimer>
#include <QString>
#include <QProcess>

class SystemMonitor : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString cpuTemp READ cpuTemp NOTIFY statsUpdated)
    Q_PROPERTY(QString gpuTemp READ gpuTemp NOTIFY statsUpdated)
    Q_PROPERTY(QString ramUsage READ ramUsage NOTIFY statsUpdated)
    Q_PROPERTY(QString diskSpace READ diskSpace NOTIFY statsUpdated)
    Q_PROPERTY(QString cpuLoad READ cpuLoad NOTIFY statsUpdated)
    Q_PROPERTY(QString uptime READ uptime NOTIFY statsUpdated)
    Q_PROPERTY(QString throttling READ throttling NOTIFY statsUpdated)
    Q_PROPERTY(QString canStatus READ canStatus NOTIFY statsUpdated)
    Q_PROPERTY(QString localIP READ localIP NOTIFY statsUpdated)
    Q_PROPERTY(QString networkStatus READ networkStatus NOTIFY statsUpdated)
    Q_PROPERTY(QString wifiSSID READ wifiSSID NOTIFY statsUpdated)
    Q_PROPERTY(QString powerDraw READ powerDraw NOTIFY statsUpdated)
    Q_PROPERTY(bool vncActive READ vncActive NOTIFY statsUpdated)
    Q_PROPERTY(bool updateActive READ updateActive NOTIFY updateStateChanged)
    Q_PROPERTY(int updateProgress READ updateProgress NOTIFY updateStateChanged)
    Q_PROPERTY(QString updateStep READ updateStep NOTIFY updateStateChanged)
    Q_PROPERTY(QString updateLog READ updateLog NOTIFY updateStateChanged)
    Q_PROPERTY(bool updateFailed READ updateFailed NOTIFY updateStateChanged)

public:
    explicit SystemMonitor(QObject *parent = nullptr);
    QString cpuTemp() const { return m_cpuTemp; }
    QString gpuTemp() const { return m_gpuTemp; }
    QString ramUsage() const { return m_ramUsage; }
    QString diskSpace() const { return m_diskSpace; }
    QString cpuLoad() const { return m_cpuLoad; }
    QString uptime() const { return m_uptime; }
    QString throttling() const { return m_throttling; }
    QString canStatus() const { return m_canStatus; }
    QString localIP() const { return m_localIP; }
    QString networkStatus() const { return m_networkStatus; }
    QString wifiSSID() const { return m_wifiSSID; }
    QString vncStatus() const { return m_vncActive ? "AKTYWNY" : "WYŁĄCZONY"; }
    QString powerDraw() const { return m_powerDraw; }
    bool vncActive() const { return m_vncActive; }
    Q_INVOKABLE void rebootSystem();
    Q_INVOKABLE void shutdownSystem();
    Q_INVOKABLE void restartDashService();
    Q_INVOKABLE void toggleVnc();
    bool updateActive() const { return m_updateActive; }
    int updateProgress() const { return m_updateProgress; }
    QString updateStep() const { return m_updateStep; }
    QString updateLog() const { return m_updateLog; }
    bool updateFailed() const { return m_updateFailed; }
    Q_INVOKABLE void runInteractiveUpdate();
    Q_INVOKABLE void cancelOrDismissUpdate();

signals:
    void statsUpdated();
    void updateStateChanged();

private slots:
    void updateMetrics();
    void onUpdateOutputReady();
    void onUpdateFinished(int exitCode, QProcess::ExitStatus exitStatus);

private:
    QTimer m_timer;
    QString m_cpuTemp{"-- °C"};
    QString m_gpuTemp{"-- °C"};
    QString m_ramUsage{"-- %"};
    QString m_diskSpace{"--"};
    QString m_cpuLoad{"-- %"};
    QString m_uptime{"--"};
    QString m_throttling{"OK"};
    QString m_canStatus{"BRAK"};
    QString m_localIP{"0.0.0.0"};
    QString m_networkStatus{"--"};
    QString m_wifiSSID{"--"};
    QString m_powerDraw{"-- W"};
    bool m_vncActive{false};
    unsigned long long m_prevIdleTime{0};
    unsigned long long m_prevTotalTime{0};
    void readCpuTemp();
    void readGpuTemp();
    void readRamUsage();
    void readDiskSpace();
    void readCpuLoad();
    void readUptime();
    void readThrottling();
    void readCanStatus();
    void readNetworkInfo();
    void readVncStatus();
    void readPowerDraw();
    QProcess *m_updateProcess{nullptr};
    bool m_updateActive{false};
    int m_updateProgress{0};
    QString m_updateStep{""};
    QString m_updateLog{""};
    bool m_updateFailed{false};
};
