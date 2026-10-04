#include "SystemMonitor.h"
#include <QFile>
#include <QTextStream>
#include <QNetworkInterface>
#include <QProcess>
#ifdef Q_OS_LINUX
#include <unistd.h>
#include <sys/reboot.h>
#include <sys/statvfs.h>
#endif

SystemMonitor::SystemMonitor(QObject *parent) : QObject(parent) {
    connect(&m_timer, &QTimer::timeout, this, &SystemMonitor::updateMetrics);
    m_timer.start(1000);
    updateMetrics();
}

void SystemMonitor::updateMetrics() {
    readCpuTemp();
    readGpuTemp();
    readRamUsage();
    readDiskSpace();
    readCpuLoad();
    readUptime();
    readThrottling();
    readCanStatus();
    readNetworkInfo();
    readVncStatus();
    readPowerDraw();
    emit statsUpdated();
}

void SystemMonitor::readCpuTemp() {
    QFile file("/sys/class/thermal/thermal_zone0/temp");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        int rawTemp = file.readAll().trimmed().toInt();
        m_cpuTemp = QString::number(rawTemp/1000.0, 'f', 1) + " °C";
        file.close();
    } else {
        m_cpuTemp = "N/A";
    }
}

void SystemMonitor::readGpuTemp() {
    QProcess proc;
    proc.start("vcgencmd", QStringList() << "measure_temp");
    if (proc.waitForFinished(100)) {
        QString out = proc.readAllStandardOutput().trimmed();
        out.remove("temp=").remove("'C");
        double val = out.toDouble();
        m_gpuTemp = QString::number(val, 'f', 1) + " °C";
    } else {
        m_gpuTemp = m_cpuTemp;
    }
}

void SystemMonitor::readRamUsage() {
    QFile file("/proc/meminfo");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        long totalKb = 0, availKb = 0;
        while (!in.atEnd()) {
            QString line = in.readLine();
            if (line.startsWith("MemTotal:")) totalKb = line.split(" ", Qt::SkipEmptyParts).value(1).toLong();
            else if (line.startsWith("MemAvailable:")) {
                availKb = line.split(" ", Qt::SkipEmptyParts).value(1).toLong();
                break;
            }
        }
        file.close();
        if (totalKb > 0) {
            long usedKb = totalKb - availKb;
            int percent = static_cast<int>((usedKb * 100.0)/totalKb);
            m_ramUsage = QString("%1% (%2 MB)").arg(percent).arg(usedKb/1024);
        }
    }
}

void SystemMonitor::readDiskSpace() {
#ifdef Q_OS_LINUX
    struct statvfs stat;
    if (statvfs("/", &stat) == 0) {
        double freeGb = (double)(stat.f_bavail * stat.f_frsize)/(1024*1024*1024);
        m_diskSpace = QString::number(freeGb, 'f', 1) + " GB";
    } else {
        m_diskSpace = "N/A";
    }
#endif
}

void SystemMonitor::readCpuLoad() {
    QFile file("/proc/stat");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        QString line = in.readLine();
        file.close();
        QStringList parts = line.split(" ", Qt::SkipEmptyParts);
        if (parts.size() >= 5) {
            unsigned long long user = parts[1].toULongLong();
            unsigned long long nice = parts[2].toULongLong();
            unsigned long long system = parts[3].toULongLong();
            unsigned long long idle = parts[4].toULongLong();
            unsigned long long iowait = parts.size() > 5 ? parts[5].toULongLong() : 0;
            unsigned long long irq = parts.size() > 6 ? parts[6].toULongLong() : 0;
            unsigned long long softirq = parts.size() > 7 ? parts[7].toULongLong() : 0;
            unsigned long long idleTime = idle + iowait;
            unsigned long long totalTime = user + nice + system + idle + iowait + irq + softirq;
            if (m_prevTotalTime != 0) {
                unsigned long long totalDelta = totalTime - m_prevTotalTime;
                unsigned long long idleDelta = idleTime - m_prevIdleTime;
                if (totalDelta > 0) {
                    double load = (1.0 - (double)idleDelta/totalDelta) * 100.0;
                    m_cpuLoad = QString::number(load, 'f', 0) + "%";
                }
            }
            m_prevIdleTime = idleTime;
            m_prevTotalTime = totalTime;
        }
    }
}

void SystemMonitor::readUptime() {
    QFile file("/proc/uptime");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        double seconds = file.readAll().split(' ').value(0).toDouble();
        file.close();
        int hrs = static_cast<int>(seconds)/3600;
        int mins = (static_cast<int>(seconds) % 3600)/60;
        m_uptime = QString("%1h %2m").arg(hrs).arg(mins);
    }
}

void SystemMonitor::readThrottling() {
    QProcess process;
    process.start("vcgencmd", QStringList() << "get_thtrottled");
    if (process.waitForFinished(100)) {
        QString out = process.readAllStandardOutput().trimmed();
        if (out.contains("0x0")) {
            m_throttling = "OK";
        } else if (out.contains("0x50000") || out.contains("0x50005")) {
            m_throttling = "THROTTLED";
        } else if (!out.isEmpty()) {
            m_throttling = "UNDERVOLT";
        }
    } else {
        m_throttling = "N/A";
    }
}

void SystemMonitor::readPowerDraw() {
    QFile powerFile("/sys/devices/platform/axi/axi:power_sensor/hwmon/hwmon0/power1_input");
    if (!powerFile.exists()) {
        powerFile.setFileName("/sys/class/hwmon/hwmon0/power1_input");
    }
    if (powerFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        double microwatts = powerFile.readAll().trimmed().toDouble();
        double watts = microwatts / 1000000.0;
        m_powerDraw = QString::number(watts, 'f', 2) + " W";
        powerFile.close();
    }
}

void SystemMonitor::readCanStatus() {
    QFile can0State("/sys/class/net/can0/operstate");
    QString state0 = "DOWN";
    if (can0State.open(QIODevice::ReadOnly | QIODevice::Text)) {
        state0 = can0State.readAll().trimmed().toUpper();
        can0State.close();
    }
    QFile can1State("/sys/class/net/can1/operstate");
    QString state1 = "DOWN";
    if (can1State.open(QIODevice::ReadOnly | QIODevice::Text)) {
        state1 = can1State.readAll().trimmed().toUpper();
        can1State.close();
    }
    if (state0 == "UP" && state1 == "UP") m_canStatus = "OK";
    else if (state0 == "UP") m_canStatus = "OK";
    else if (state1 == "UP") m_canStatus = "OK";
    else m_canStatus = "ERR";
}

void SystemMonitor::readNetworkInfo() {
    QString foundIP = "--";
    bool hasConnection = false;
    const QList<QHostAddress> addresses = QNetworkInterface::allAddresses();
    for (const QHostAddress &addr : addresses) {
        if (addr.protocol() == QAbstractSocket::IPv4Protocol && !addr.isLoopback()) {
            foundIP = addr.toString();
            hasConnection = true;
            break;
        }
    }
    m_localIP = foundIP;
    m_networkStatus = hasConnection ? "POŁĄCZONO" : "BRAK";
    QFile wifiFile("/proc/net/wireless");
    if (wifiFile.exists()) {
        QProcess proc;
        proc.start("iwgetid", QStringList() << "-r");
        if (proc.waitForFinished(100)) {
            QString ssid = proc.readAllStandardOutput().trimmed();
            m_wifiSSID = ssid.isEmpty() ? "BRAK" : ssid;
        }
    } else {
        m_wifiSSID = "--";
    }
}

void SystemMonitor::readVncStatus() {
    QProcess proc;
    proc.start("systemctl", QStringList() << "is-active" << "dash-vnc.service");
    if (proc.waitForFinished(100)) {
        m_vncActive = (proc.readAllStandardOutput().trimmed() == "active");
    } else {
        m_vncActive = false;
    }
}

void SystemMonitor::toggleVnc() {
    if (m_vncActive) {
        QProcess::startDetached("systemctl", QStringList() << "stop" << "dash-vnc.service");
    } else {
        QProcess::startDetached("systemctl", QStringList() << "start" << "dash-vnc.service");
    }
}

void SystemMonitor::rebootSystem() {
    QProcess::startDetached("systemctl", QStringList() << "reboot");
}

void SystemMonitor::shutdownSystem() {
    QProcess::startDetached("systemctl", QStringList() << "poweroff");
}

void SystemMonitor::restartDashService() {
    QProcess::startDetached("systemctl", QStringList() << "restart" << "dash.service");
}

void SystemMonitor::runInteractiveUpdate() {
#ifdef Q_OS_LINUX
    if (m_updateActive) return;
    m_updateActive = true;
    m_updateFailed = false;
    m_updateProgress = 5;
    m_updateStep = "Inicjalizacja aktualizacji...";
    m_updateLog = "";
    emit updateStateChanged();
    if (!m_updateProcess) {
        m_updateProcess = new QProcess(this);
        connect(m_updateProcess, &QProcess::readyStandardOutput, this, &SystemMonitor::onUpdateOutputReady);
        connect(m_updateProcess, &QProcess::readyReadStandardError, this, &SystemMonitor::onUpdateOutputReady);
        connect(m_updateProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
                this, &SystemMonitor::onUpdateFinished);
    }
    m_updateProcess->start("/usr/local/bin/dash-update-worker.sh");
#endif
}

void SystemMonitor::onUpdateOutputReady() {
    if (!m_updateProcess) return;
    while (m_updateProcess->canReadLine()) {
        QString line = QString::fromUtf8(m_updateProcess->readLine()).trimmed();
        if (line.isEmpty()) continue;
        m_updateLog = line;
        if (line.startsWith("[PROGRESS:")) {
            QString val = line.section(':', 1, 1).remove(']');
            m_updateProgress = val.toInt();
        } else if (line.startsWith("[STEP:")) {
            m_updateStep = line.section(':', 1).chopped(1);
        } else if (line.startsWith("[ERROR:")) {
            m_updateStep = line.section(':', 1).chopped(1);
            m_updateFailed = true;
        }
        emit updateStateChanged();
    }
}

void SystemMonitor::onUpdateFinished(int exitCode, QProcess::ExitStatus exitStatus) {
    Q_UNUSED(exitStatus);
    if (exitCode == 0 && !m_updateFailed) {
        m_updateProgress = 100;
        m_updateStep = "Success! Restarting Dash...";
        emit updateStateChanged();
#ifdef Q_OS_LINUX
        QProcess::startDetached("bash", QStringList() << "-c" << "sleep 1.5 && systemctl restart dash.service");
#endif
    } else {
        m_updateFailed = true;
        if (m_updateStep.isEmpty()) m_updateStep = "Error during update process";
    }
}

void SystemMonitor::cancelOrDismissUpdate() {
    if (m_updateActive && m_updateProcess && m_updateProcess->state() == QProcess::Running) {
        m_updateProcess->kill();
    }
    m_updateActive = false;
    m_updateFailed = false;
    emit updateStateChanged();
}


