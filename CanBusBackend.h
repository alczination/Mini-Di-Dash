#ifndef CANBUSBACKEND_H
#define CANBUSBACKEND_H

#include <QObject>
#include <QThread>
#include <QDebug>
#include <atomic>

// Linux
#ifdef Q_OS_LINUX
#include <unistd.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <linux/can.h>
#include <linux/can/raw.h>
#endif

// CAN-Worker for Linux only
class CanWorker : public QObject
{
    Q_OBJECT
public:
    explicit CanWorker(QObject *parent = nullptr) : QObject(parent), m_running(false) {}

public slots:
    void startWorker() {
        m_running = true;

#ifdef Q_OS_LINUX
        int socketCAN = socket(PF_CAN, SOCK_RAW, CAN_RAW);
        if (socketCAN < 0) {
            qWarning() << "SocketCAN FAIL!";
            return;
        }

        struct ifreq ifr;
        strcpy(ifr.ifr_name, "can0");
        if (ioctl(socketCAN, SIOCGIFINDEX, &ifr) < 0) {
            qWarning() << "ioctl FAIL!";
            close(socketCAN);
            return;
        }

        struct sockaddr_can addr;
        addr.can_family = PF_CAN;
        addr.can_ifindex = ifr.ifr_ifindex;
        if (bind(socketCAN, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
            qWarning() << "bind FAIL!";
            close(socketCAN);
            return;
        }

        struct timeval tv;
        tv.tv_sec = 0;
        tv.tv_usec = 500000; // 500ms timeout
        setsockopt(socketCAN, SOL_SOCKET, SO_RCVTIMEO, (const char*)&tv, sizeof(tv));

        struct can_frame frame;
        while (m_running) {
            int nbytes = read(socketCAN, &frame, sizeof(frame));
            if (nbytes > 0) {
                parseFrame(frame);
            }
        }

        close(socketCAN);
#else
        qInfo() << "App run on Windows/MacOS - SocketCAN disabled";
#endif
    }

    void stopWorker() {
        m_running = false;
    }

signals:
    void speedReceived(int value);
    void wheelSpeedsReceived(double lf, double rf, double lr, double rr);
    void rpmReceived(int value);
    void mileageReceived(int value);
    void oilTempReceived(double value);
    void oilPressReceived(double value);
    void engineTempReceived(double value);
    void fuelReceived(double value);
    void rangeKmReceived(int range);
    void fuelReserveChanged(bool active);
    void avgConsumptionReceived(double value);
    void turboReceived(double bar);
    void throttleReceived(double value);
    void tempReceived(double value);
    void doorLeftStatusReceived(bool open);
    void doorRightStatusReceived(bool open);
    void hoodStatusReceived(bool open);
    void trunkStatusReceived(bool open);
    void absWarningReceived(bool active);
    void tractionWarningReceived(bool active);
    void handbrakeReceived(bool active);
    void engineMilStatusReceived(bool active);
    void clusterLightsReceived(bool leftBlinker, bool rightBlinker, bool highBeam, bool handbrake);

private:
    std::atomic<bool> m_running;
    bool m_firstClickRecorded = false;
    uint8_t m_lastFuelClick = 0;
    double m_currentLitersPerHundred = 0.0;
    double m_lastKnownSpeed = 0.0;

#ifdef Q_OS_LINUX
    void parseFrame(const struct can_frame &frame) {
        switch (frame.can_id) {

        case 0x153: {
            if (frame.can_dlc >= 3) {
                uint8_t b1 = static_cast<uint8_t>(frame.data[1]);
                uint8_t b2 = static_cast<uint8_t>(frame.data[2]);
                uint16_t raw_speed = ((b2 << 8) | b1) >> 3;
                raw_speed &= 0x1FFF;
                double speed_calc = (static_cast<double>(raw_speed) * 0.0625) - 0.625;
                if (speed_calc < 0) speed_calc = 0;

                emit speedReceived(static_cast<int>(speed_calc));
                m_lastKnownSpeed = speed_calc;

                uint8_t byte0 = static_cast<uint8_t>(frame.data[0]);
                emit absWarningReceived((byte0 & 0x80) != 0);

                uint8_t byte1 = static_cast<uint8_t>(frame.data[1]);
                emit tractionWarningReceived((byte1 & 0x02) != 0);
            }
            break;
        }

        case 0x1F0: {
            if (frame.can_dlc >= 8) {
                uint8_t d0 = static_cast<uint8_t>(frame.data[0]);
                uint8_t d1 = static_cast<uint8_t>(frame.data[1]);
                uint8_t d2 = static_cast<uint8_t>(frame.data[2]);
                uint8_t d3 = static_cast<uint8_t>(frame.data[3]);
                uint8_t d4 = static_cast<uint8_t>(frame.data[4]);
                uint8_t d5 = static_cast<uint8_t>(frame.data[5]);
                uint8_t d6 = static_cast<uint8_t>(frame.data[6]);
                uint8_t d7 = static_cast<uint8_t>(frame.data[7]);

                uint16_t lf_raw = (d0 | (d1 << 8)) & 0x0FFF;
                uint16_t rf_raw = (d2 | (d3 << 8)) & 0x0FFF;
                uint16_t lr_raw = (d4 | (d5 << 8)) & 0x0FFF;
                uint16_t rr_raw = (d6 | (d7 << 8)) & 0x0FFF;

                emit wheelSpeedsReceived(
                    lf_raw * 0.0625,
                    rf_raw * 0.0625,
                    lr_raw * 0.0625,
                    rr_raw * 0.0625
                    );
            }
            break;
        }

        case 0x316: {
            if (frame.can_dlc >= 4) {
                uint8_t lsb = static_cast<uint8_t>(frame.data[2]);
                uint8_t msb = static_cast<uint8_t>(frame.data[3]);
                int raw_value = (static_cast<int>(msb) << 8) | lsb;
                double rpm_value = static_cast<double>(raw_value) * 0.15625;
                int rpm = static_cast<int>(rpm_value);
                if (rpm < 0) rpm = 0;
                if (rpm > 9000) rpm = 9000;

                emit rpmReceived(rpm);
            }
            break;
        }

        case 0x329: {
            if (frame.can_dlc >= 6) {
                uint8_t temp_raw = static_cast<uint8_t>(frame.data[1]);
                if (temp_raw != 0x00 && temp_raw != 0xFF) {
                    double engine_temp = (static_cast<double>(temp_raw) * 0.75) - 48.0;
                    emit engineTempReceived(engine_temp);
                }

                uint8_t throttle_raw = static_cast<uint8_t>(frame.data[5]);
                double throttle_pct = static_cast<double>(throttle_raw);
                if (throttle_pct > 100.0) throttle_pct = 100.0;
                if (throttle_pct < 0.0) throttle_pct = 0.0;

                emit throttleReceived(throttle_pct);
            }
            break;
        }

        case 0x545: {
            if (frame.can_dlc >= 5) {
                uint8_t status_byte = static_cast<uint8_t>(frame.data[0]);
                emit engineMilStatusReceived((status_byte & 0x02) != 0);

                uint8_t currentClick = static_cast<uint8_t>(frame.data[2]);
                if (!m_firstClickRecorded) {
                    m_lastFuelClick = currentClick;
                    m_firstClickRecorded = true;
                } else {
                    int delta = (currentClick >= m_lastFuelClick)
                    ? (currentClick - m_lastFuelClick)
                    : ((255 - m_lastFuelClick) + currentClick + 1);

                    m_lastFuelClick = currentClick;
                    double litersPerHour = delta * 1.5;

                    if (m_lastKnownSpeed > 5.0) {
                        double instantConsumption = (litersPerHour / m_lastKnownSpeed) * 100.0;
                        m_currentLitersPerHundred = (m_currentLitersPerHundred * 0.995) + (instantConsumption * 0.005);
                    }

                    emit avgConsumptionReceived(m_currentLitersPerHundred);
                }

                uint8_t oil_raw = static_cast<uint8_t>(frame.data[4]);
                double oil_temp = (oil_raw == 0x00 || oil_raw == 0xFF)
                                      ? 0.0
                                      : (static_cast<double>(oil_raw) - 48.373);

                emit oilTempReceived(oil_temp);
            }
            break;
        }

        case 0x565: {
            if (frame.can_dlc >= 7) {
                uint8_t oil_raw = static_cast<uint8_t>(frame.data[6]);
                double oil_press_bar = (static_cast<double>(oil_raw) * 2.0) / 100.0;
                emit oilPressReceived(oil_press_bar);
            }
            break;
        }

        case 0x613: {
            if (frame.can_dlc >= 3) {
                uint8_t fuel_raw = static_cast<uint8_t>(frame.data[2]);
                double fuel = static_cast<double>(fuel_raw & 0x7F);

                emit fuelReceived(fuel);

                double averageConsumption = m_currentLitersPerHundred;
                int range = (fuel > 0.0 && averageConsumption > 0.0)
                                ? static_cast<int>((fuel / averageConsumption) * 100.0)
                                : 0;

                emit rangeKmReceived(range);

                bool reserveActive = (fuel_raw & 0x80) != 0;
                emit fuelReserveChanged(reserveActive);
            }
            break;
        }

        case 0x615: {
            if (frame.can_dlc >= 5) {
                uint8_t byte1 = static_cast<uint8_t>(frame.data[1]);
                uint8_t byte3 = static_cast<uint8_t>(frame.data[3]);
                uint8_t byte4 = static_cast<uint8_t>(frame.data[4]);

                emit handbrakeReceived((byte4 & 0x02) != 0);
                emit hoodStatusReceived((byte1 & 0x08) != 0);

                double outdoor_temp = static_cast<double>(byte3 & 0x7F);
                if ((byte3 & 0x80) != 0) {
                    outdoor_temp = -outdoor_temp;
                }

                emit tempReceived(outdoor_temp);
            }
            break;
        }

        case 0x61A: {
            if (frame.can_dlc >= 3) {
                uint32_t b0 = static_cast<uint8_t>(frame.data[0]);
                uint32_t b1 = static_cast<uint8_t>(frame.data[1]);
                uint32_t b2 = static_cast<uint8_t>(frame.data[2]) & 0x0F;

                int mileage = static_cast<int>((b2 << 16) | (b1 << 8) | b0);

                if (mileage > 0) {
                    emit mileageReceived(mileage);
                }
            }
            break;
        }

        default:
            break;
        }
    }
#endif
};

// 2. BACKEND API FOR QML / MAIN
class CanBusBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int rpm READ rpm NOTIFY rpmChanged)
    Q_PROPERTY(int speed READ speed NOTIFY speedChanged)
    Q_PROPERTY(double oilTemp READ oilTemp NOTIFY oilTempChanged)
    Q_PROPERTY(double oilPress READ oilPress NOTIFY oilPressChanged)
    Q_PROPERTY(double engineTemp READ engineTemp NOTIFY engineTempChanged)
    Q_PROPERTY(double fuelAmount READ fuelAmount NOTIFY fuelAmountChanged)
    Q_PROPERTY(int rangeKm READ rangeKm NOTIFY rangeKmChanged)
    Q_PROPERTY(double turbo READ turbo NOTIFY turboChanged)

public:
    explicit CanBusBackend(QObject *parent = nullptr)
        : QObject(parent),
        m_rpm(0), m_speed(0), m_oilTemp(0.0), m_oilPress(0.0),
        m_engineTemp(0.0), m_fuelAmount(0.0), m_rangeKm(0), m_turbo(0.0)
    {
        m_worker = new CanWorker();
        m_worker->moveToThread(&m_workerThread);

        connect(&m_workerThread, &QThread::started, m_worker, &CanWorker::startWorker);
        connect(&m_workerThread, &QThread::finished, m_worker, &QObject::deleteLater);

        connect(m_worker, &CanWorker::rpmReceived, this, &CanBusBackend::setRpm);
        connect(m_worker, &CanWorker::speedReceived, this, &CanBusBackend::setSpeed);
        connect(m_worker, &CanWorker::oilTempReceived, this, &CanBusBackend::setOilTemp);
        connect(m_worker, &CanWorker::oilPressReceived, this, &CanBusBackend::setOilPress);
        connect(m_worker, &CanWorker::engineTempReceived, this, &CanBusBackend::setEngineTemp);
        connect(m_worker, &CanWorker::fuelReceived, this, &CanBusBackend::setFuelAmount);
        connect(m_worker, &CanWorker::rangeKmReceived, this, &CanBusBackend::setRangeKm);
        connect(m_worker, &CanWorker::turboReceived, this, &CanBusBackend::setTurbo);
        connect(m_worker, &CanWorker::wheelSpeedsReceived, this, &CanBusBackend::wheelSpeedsReceived);
        connect(m_worker, &CanWorker::mileageReceived, this, &CanBusBackend::mileageReceived);
        connect(m_worker, &CanWorker::fuelReserveChanged, this, &CanBusBackend::fuelReserveChanged);
        connect(m_worker, &CanWorker::avgConsumptionReceived, this, &CanBusBackend::avgConsumptionReceived);
        connect(m_worker, &CanWorker::throttleReceived, this, &CanBusBackend::throttleReceived);
        connect(m_worker, &CanWorker::tempReceived, this, &CanBusBackend::tempReceived);
        connect(m_worker, &CanWorker::doorLeftStatusReceived, this, &CanBusBackend::doorLeftStatusReceived);
        connect(m_worker, &CanWorker::doorRightStatusReceived, this, &CanBusBackend::doorRightStatusReceived);
        connect(m_worker, &CanWorker::hoodStatusReceived, this, &CanBusBackend::hoodStatusReceived);
        connect(m_worker, &CanWorker::trunkStatusReceived, this, &CanBusBackend::trunkStatusReceived);
        connect(m_worker, &CanWorker::absWarningReceived, this, &CanBusBackend::absWarningReceived);
        connect(m_worker, &CanWorker::tractionWarningReceived, this, &CanBusBackend::tractionWarningReceived);
        connect(m_worker, &CanWorker::handbrakeReceived, this, &CanBusBackend::handbrakeReceived);
        connect(m_worker, &CanWorker::engineMilStatusReceived, this, &CanBusBackend::engineMilStatusReceived);
        connect(m_worker, &CanWorker::clusterLightsReceived, this, &CanBusBackend::clusterLightsReceived);

        m_workerThread.start();
    }

    ~CanBusBackend() override {
        if (m_worker) {
            m_worker->stopWorker();
        }
        m_workerThread.quit();
        m_workerThread.wait();
    }

    // Getters QML
    int rpm() const { return m_rpm; }
    int speed() const { return m_speed; }
    double oilTemp() const { return m_oilTemp; }
    double oilPress() const { return m_oilPress; }
    double engineTemp() const { return m_engineTemp; }
    double fuelAmount() const { return m_fuelAmount; }
    int rangeKm() const { return m_rangeKm; }
    double turbo() const { return m_turbo; }

public slots:
    void setRpm(int r) { if (m_rpm != r) { m_rpm = r; emit rpmChanged(); } }
    void setSpeed(int s) { if (m_speed != s) { m_speed = s; emit speedChanged(); } }
    void setOilTemp(double t) { if (m_oilTemp != t) { m_oilTemp = t; emit oilTempChanged(); } }
    void setOilPress(double p) { if (m_oilPress != p) { m_oilPress = p; emit oilPressChanged(); } }
    void setEngineTemp(double e) { if (m_engineTemp != e) { m_engineTemp = e; emit engineTempChanged(); } }
    void setFuelAmount(double f) { if (m_fuelAmount != f) { m_fuelAmount = f; emit fuelAmountChanged(); } }
    void setRangeKm(int r) { if (m_rangeKm != r) { m_rangeKm = r; emit rangeKmChanged(); } }
    void setTurbo(double tb) { if (m_turbo != tb) { m_turbo = tb; emit turboChanged(); } }

signals:
    void rpmChanged();
    void speedChanged();
    void oilTempChanged();
    void oilPressChanged();
    void engineTempChanged();
    void fuelAmountChanged();
    void rangeKmChanged();
    void turboChanged();

    void wheelSpeedsReceived(double lf, double rf, double lr, double rr);
    void mileageReceived(int value);
    void fuelReserveChanged(bool active);
    void avgConsumptionReceived(double value);
    void throttleReceived(double value);
    void tempReceived(double value);
    void doorLeftStatusReceived(bool open);
    void doorRightStatusReceived(bool open);
    void hoodStatusReceived(bool open);
    void trunkStatusReceived(bool open);
    void absWarningReceived(bool active);
    void tractionWarningReceived(bool active);
    void handbrakeReceived(bool active);
    void engineMilStatusReceived(bool active);
    void clusterLightsReceived(bool leftBlinker, bool rightBlinker, bool highBeam, bool handbrake);

private:
    QThread m_workerThread;
    CanWorker *m_worker;

    int m_rpm;
    int m_speed;
    double m_oilTemp;
    double m_oilPress;
    double m_engineTemp;
    double m_fuelAmount;
    int m_rangeKm;
    double m_turbo;
};

#endif // CANBUSBACKEND_H
