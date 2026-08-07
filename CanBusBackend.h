#ifndef CANBUSBACKEND_H
#define CANBUSBACKEND_H

#include <QObject>
#include <QThread>
#include <QDebug>
#include <QTimer>
#include <QProcess>
#include <QCoreApplication>
#include <atomic>

// Linux SocketCAN
#ifdef Q_OS_LINUX
#include <unistd.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <linux/can.h>
#include <linux/can/raw.h>
#endif

// ============================================================================
// CAN WORKER
// ============================================================================
class CanWorker : public QObject
{
    Q_OBJECT
public:
    explicit CanWorker(QObject *parent = nullptr) : QObject(parent), m_running(false) {}

public slots:
    void startWorker() {
        m_running = true;

        // Inicjalizacja Watchdoga wewnątrz wątku pracownika
        m_watchdogTimer = new QTimer(this);
        connect(m_watchdogTimer, &QTimer::timeout, this, &CanWorker::onCanTimeout);
        m_watchdogTimer->start(15000); // 15 sekund braku ramek = uśpienie

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
        tv.tv_usec = 200000; // 200ms timeout na odczyt z gniazda (daje czas dla pętli zdarzeń)
        setsockopt(socketCAN, SOL_SOCKET, SO_RCVTIMEO, (const char*)&tv, sizeof(tv));

        struct can_frame frame;
        while (m_running) {
            int nbytes = read(socketCAN, &frame, sizeof(frame));
            if (nbytes > 0) {
                parseFrame(frame);
            }

            // KLUCZOWE: Pozwól pętli zdarzeń Qt wykonać zdarzenia QTimer w tym wątku
            QCoreApplication::processEvents();
        }

        close(socketCAN);
#else
        qInfo() << "App run on Windows/MacOS - SocketCAN disabled";
#endif
    }

    void stopWorker() {
        m_running = false;
        if (m_watchdogTimer) {
            m_watchdogTimer->stop();
        }
    }

private slots:
    void onCanTimeout() {
        qWarning() << "No CAN Frames for 15 sec. Going sleep mode";
        m_running = false;
        QProcess::execute("vcgencmd display_power 0");
        QProcess::execute("systemctl poweroff -i");
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
    void instantConsumptionReceived(double value);
    void turboReceived(double bar);
    void throttleReceived(double value);
    void tempReceived(double value);
    void doorLeftStatusReceived(bool open);
    void doorRightStatusReceived(bool open);
    void hoodStatusReceived(bool open);
    void lightsStatusReceived(bool enabled);
    void trunkStatusReceived(bool open);
    void absWarningReceived(bool active);
    void tractionWarningReceived(bool active);
    void handbrakeReceived(bool active);
    void engineMilStatusReceived(bool active);
    void clusterLightsReceived(bool leftBlinker, bool rightBlinker, bool highBeam, bool handbrake);

private:
    std::atomic<bool> m_running;
    QTimer *m_watchdogTimer = nullptr;
    bool m_firstClickRecorded = false;
    uint16_t m_lastFuelClick = 0;
    double m_currentLitersPerHundred = 0.0;
    double m_lastKnownSpeed = 0.0;
    double m_currentFuelLiters = 0.0;

#ifdef Q_OS_LINUX
    void parseFrame(const struct can_frame &frame) {
        // RESETUJEMY WATCHDOG TYLKO DLA KLUCZOWYCH RAMEK SILNIKA (RPM / Prędkość)
        if (frame.can_id == 0x316 || frame.can_id == 0x153) {
            if (m_watchdogTimer) {
                m_watchdogTimer->start(15000);
            }
        }

        switch (frame.can_id) {

        // Speed, ABS Warning, Traction Warning
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

        // Wheel speeds
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

        // RPM
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

        // Engine Temp & Throttle %
        case 0x329: {
            if (frame.can_dlc >= 6) {
                uint8_t temp_raw = static_cast<uint8_t>(frame.data[1]);
                if (temp_raw != 0x00 && temp_raw != 0xFF) {
                    double engine_temp = (static_cast<double>(temp_raw) * 0.75) - 48.0;
                    emit engineTempReceived(engine_temp);
                }

                uint8_t throttle_raw = static_cast<uint8_t>(frame.data[5]);
                double throttle_pct = static_cast<double>(throttle_raw) * 0.390625;
                if (throttle_pct > 100.0) throttle_pct = 100.0;
                if (throttle_pct < 0.0) throttle_pct = 0.0;

                emit throttleReceived(throttle_pct);
            }
            break;
        }

        // MIL status, Oil temp, Fuel consumption (FCO 16-bit)
        case 0x545: {
            if (frame.can_dlc >= 3) {
                uint8_t status_byte = static_cast<uint8_t>(frame.data[0]);
                emit engineMilStatusReceived((status_byte & 0x02) != 0);

                uint8_t fco_lsb = static_cast<uint8_t>(frame.data[1]);
                uint8_t fco_msb = static_cast<uint8_t>(frame.data[2]);
                uint16_t currentFco = (static_cast<uint16_t>(fco_msb) << 8) | fco_lsb;

                if (!m_firstClickRecorded) {
                    m_lastFuelClick = currentFco;
                    m_firstClickRecorded = true;
                } else {
                    uint16_t delta = 0;
                    if (currentFco >= m_lastFuelClick) {
                        delta = currentFco - m_lastFuelClick;
                    } else {
                        delta = (65535 - m_lastFuelClick) + currentFco + 1;
                    }
                    m_lastFuelClick = currentFco;

                    double litersPerHour = static_cast<double>(delta) * 1.5;

                    if (m_lastKnownSpeed > 2.0) {
                        double instantConsumption = (litersPerHour / m_lastKnownSpeed) * 100.0;
                        m_currentLitersPerHundred = (m_currentLitersPerHundred * 0.98) + (instantConsumption * 0.02);
                        emit instantConsumptionReceived(instantConsumption);
                    } else {
                        emit instantConsumptionReceived(litersPerHour);
                    }

                    emit avgConsumptionReceived(m_currentLitersPerHundred);

                    if (m_currentFuelLiters > 0.0 && m_currentLitersPerHundred > 0.0) {
                        int calculatedRange = static_cast<int>((m_currentFuelLiters / m_currentLitersPerHundred) * 100.0);
                        emit rangeKmReceived(calculatedRange);
                    }
                }
            }

            if (frame.can_dlc >= 5) {
                uint8_t oil_raw = static_cast<uint8_t>(frame.data[4]);
                double oil_temp = (oil_raw == 0x00 || oil_raw == 0xFF)
                                      ? 0.0
                                      : (static_cast<double>(oil_raw) - 48.373);

                emit oilTempReceived(oil_temp);
            }
            break;
        }

        // Oil Pressure
        case 0x565: {
            if (frame.can_dlc >= 7) {
                uint8_t oil_raw = static_cast<uint8_t>(frame.data[6]);
                double oil_press_bar = (static_cast<double>(oil_raw) * 2.0) / 100.0;
                emit oilPressReceived(oil_press_bar);
            }
            break;
        }

        // Fuel Level & Fuel Reserve
        case 0x613: {
            if (frame.can_dlc >= 3) {
                uint8_t fuel_raw = static_cast<uint8_t>(frame.data[2]);
                m_currentFuelLiters = static_cast<double>(fuel_raw & 0x7F);

                emit fuelReceived(m_currentFuelLiters);

                bool reserveActive = (fuel_raw & 0x80) != 0;
                emit fuelReserveChanged(reserveActive);
            }
            break;
        }

        // Statusy: Handbrake, Hood, Lights, Outdoor Temp
        case 0x615: {
            if (frame.can_dlc >= 5) {
                uint8_t byte1 = static_cast<uint8_t>(frame.data[1]);
                uint8_t byte3 = static_cast<uint8_t>(frame.data[3]);
                uint8_t byte4 = static_cast<uint8_t>(frame.data[4]);

                emit handbrakeReceived((byte4 & 0x02) != 0);
                emit hoodStatusReceived((byte1 & 0x08) != 0);
                emit lightsStatusReceived((byte1 & 0x04) != 0);

                double outdoor_temp = static_cast<double>(byte3 & 0x7F);
                if ((byte3 & 0x80) != 0) {
                    outdoor_temp = -outdoor_temp;
                }

                emit tempReceived(outdoor_temp);
            }
            break;
        }

        // Mileage & Display BC
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

            if (frame.can_dlc >= 8) {
                uint8_t b5 = static_cast<uint8_t>(frame.data[5]);
                uint8_t b6 = static_cast<uint8_t>(frame.data[6]);
                uint8_t b7 = static_cast<uint8_t>(frame.data[7]);

                uint8_t bcMode = b7 & 0x0F;
                bool isValidValue = !(b5 == 0xFE && b6 == 0x7F);

                float rawValue = 0.0f;
                if (isValidValue) {
                    uint16_t combined = (static_cast<uint16_t>(b6) << 8) | b5;
                    rawValue = combined / 10.0f;
                }

                switch (bcMode) {
                case 0x03:
                    if (isValidValue) {
                        emit rangeKmReceived(static_cast<int>(rawValue));
                    }
                    break;

                case 0x04:
                    if (isValidValue) emit avgConsumptionReceived(rawValue);
                    break;

                case 0x09:
                    if (isValidValue) emit instantConsumptionReceived(rawValue);
                    break;

                default:
                    break;
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

// ============================================================================
// BACKEND API FOR QML / MAIN
// ============================================================================
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
    Q_PROPERTY(int mileage READ mileage NOTIFY mileageChanged)
    Q_PROPERTY(bool fuelReserve READ fuelReserve NOTIFY fuelReserveChanged)
    Q_PROPERTY(double avgConsumption READ avgConsumption NOTIFY avgConsumptionChanged)
    Q_PROPERTY(double instantConsumption READ instantConsumption NOTIFY instantConsumptionChanged)
    Q_PROPERTY(double throttle READ throttle NOTIFY throttleChanged)
    Q_PROPERTY(double outdoorTemp READ outdoorTemp NOTIFY outdoorTempChanged)
    Q_PROPERTY(bool doorLeft READ doorLeft NOTIFY doorLeftStatusChanged)
    Q_PROPERTY(bool doorRight READ doorRight NOTIFY doorRightStatusChanged)
    Q_PROPERTY(bool hoodOpen READ hoodOpen NOTIFY hoodStatusChanged)
    Q_PROPERTY(bool headlightsActive READ headlightsActive NOTIFY lightsStatusChanged)
    Q_PROPERTY(bool trunkOpen READ trunkOpen NOTIFY trunkStatusChanged)
    Q_PROPERTY(bool absWarning READ absWarning NOTIFY absWarningChanged)
    Q_PROPERTY(bool tractionWarning READ tractionWarning NOTIFY tractionWarningChanged)
    Q_PROPERTY(bool handbrake READ handbrake NOTIFY handbrakeChanged)
    Q_PROPERTY(bool checkEngine READ checkEngine NOTIFY checkEngineChanged)

public:
    explicit CanBusBackend(QObject *parent = nullptr)
        : QObject(parent),
        m_rpm(0), m_speed(0), m_oilTemp(0.0), m_oilPress(0.0),
        m_engineTemp(0.0), m_fuelAmount(0.0), m_rangeKm(0), m_turbo(0.0),
        m_mileage(0), m_fuelReserve(false), m_avgConsumption(0.0), m_instantConsumption(0.0),
        m_throttle(0.0), m_outdoorTemp(0.0), m_doorLeft(false),
        m_doorRight(false), m_hoodOpen(false), m_headlightsActive(false),
        m_trunkOpen(false), m_absWarning(false), m_tractionWarning(false),
        m_handbrake(false), m_checkEngine(false)
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
        connect(m_worker, &CanWorker::mileageReceived, this, &CanBusBackend::setMileage);
        connect(m_worker, &CanWorker::fuelReserveChanged, this, &CanBusBackend::setFuelReserve);
        connect(m_worker, &CanWorker::avgConsumptionReceived, this, &CanBusBackend::setAvgConsumption);
        connect(m_worker, &CanWorker::instantConsumptionReceived, this, &CanBusBackend::setInstantConsumption);
        connect(m_worker, &CanWorker::throttleReceived, this, &CanBusBackend::setThrottle);
        connect(m_worker, &CanWorker::tempReceived, this, &CanBusBackend::setOutdoorTemp);
        connect(m_worker, &CanWorker::doorLeftStatusReceived, this, &CanBusBackend::setDoorLeft);
        connect(m_worker, &CanWorker::doorRightStatusReceived, this, &CanBusBackend::setDoorRight);
        connect(m_worker, &CanWorker::hoodStatusReceived, this, &CanBusBackend::setHoodOpen);
        connect(m_worker, &CanWorker::lightsStatusReceived, this, &CanBusBackend::setHeadlightsActive);
        connect(m_worker, &CanWorker::trunkStatusReceived, this, &CanBusBackend::setTrunkOpen);
        connect(m_worker, &CanWorker::absWarningReceived, this, &CanBusBackend::setAbsWarning);
        connect(m_worker, &CanWorker::tractionWarningReceived, this, &CanBusBackend::setTractionWarning);
        connect(m_worker, &CanWorker::handbrakeReceived, this, &CanBusBackend::setHandbrake);
        connect(m_worker, &CanWorker::engineMilStatusReceived, this, &CanBusBackend::setCheckEngine);

        connect(m_worker, &CanWorker::wheelSpeedsReceived, this, &CanBusBackend::wheelSpeedsReceived);
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
    int mileage() const { return m_mileage; }
    bool fuelReserve() const { return m_fuelReserve; }
    double avgConsumption() const { return m_avgConsumption; }
    double instantConsumption() const { return m_instantConsumption; }
    double throttle() const { return m_throttle; }
    double outdoorTemp() const { return m_outdoorTemp; }
    bool doorLeft() const { return m_doorLeft; }
    bool doorRight() const { return m_doorRight; }
    bool hoodOpen() const { return m_hoodOpen; }
    bool headlightsActive() const { return m_headlightsActive; }
    bool trunkOpen() const { return m_trunkOpen; }
    bool absWarning() const { return m_absWarning; }
    bool tractionWarning() const { return m_tractionWarning; }
    bool handbrake() const { return m_handbrake; }
    bool checkEngine() const { return m_checkEngine; }

public slots:
    void setRpm(int r) { if (m_rpm != r) { m_rpm = r; emit rpmChanged(); } }
    void setSpeed(int s) { if (m_speed != s) { m_speed = s; emit speedChanged(); } }
    void setOilTemp(double t) { if (m_oilTemp != t) { m_oilTemp = t; emit oilTempChanged(); } }
    void setOilPress(double p) { if (m_oilPress != p) { m_oilPress = p; emit oilPressChanged(); } }
    void setEngineTemp(double e) { if (m_engineTemp != e) { m_engineTemp = e; emit engineTempChanged(); } }
    void setFuelAmount(double f) { if (m_fuelAmount != f) { m_fuelAmount = f; emit fuelAmountChanged(); } }
    void setRangeKm(int r) { if (m_rangeKm != r) { m_rangeKm = r; emit rangeKmChanged(); } }
    void setTurbo(double tb) { if (m_turbo != tb) { m_turbo = tb; emit turboChanged(); } }
    void setMileage(int m) { if (m_mileage != m) { m_mileage = m; emit mileageChanged(); } }
    void setFuelReserve(bool fr) { if (m_fuelReserve != fr) { m_fuelReserve = fr; emit fuelReserveChanged(); } }
    void setAvgConsumption(double ac) { if (m_avgConsumption != ac) { m_avgConsumption = ac; emit avgConsumptionChanged(); } }
    void setInstantConsumption(double ic) { if (m_instantConsumption != ic) { m_instantConsumption = ic; emit instantConsumptionChanged(); } }
    void setThrottle(double th) { if (m_throttle != th) { m_throttle = th; emit throttleChanged(); } }
    void setOutdoorTemp(double ot) { if (m_outdoorTemp != ot) { m_outdoorTemp = ot; emit outdoorTempChanged(); } }
    void setDoorLeft(bool dl) { if (m_doorLeft != dl) { m_doorLeft = dl; emit doorLeftStatusChanged(); } }
    void setDoorRight(bool dr) { if (m_doorRight != dr) { m_doorRight = dr; emit doorRightStatusChanged(); } }
    void setHoodOpen(bool ho) { if (m_hoodOpen != ho) { m_hoodOpen = ho; emit hoodStatusChanged(); } }
    void setHeadlightsActive(bool ha) { if (m_headlightsActive != ha) { m_headlightsActive = ha; emit lightsStatusChanged(); } }
    void setTrunkOpen(bool to) { if (m_trunkOpen != to) { m_trunkOpen = to; emit trunkStatusChanged(); } }
    void setAbsWarning(bool aw) { if (m_absWarning != aw) { m_absWarning = aw; emit absWarningChanged(); } }
    void setTractionWarning(bool tw) { if (m_tractionWarning != tw) { m_tractionWarning = tw; emit tractionWarningChanged(); } }
    void setHandbrake(bool hb) { if (m_handbrake != hb) { m_handbrake = hb; emit handbrakeChanged(); } }
    void setCheckEngine(bool ce) { if (m_checkEngine != ce) { m_checkEngine = ce; emit checkEngineChanged(); } }

signals:
    void rpmChanged();
    void speedChanged();
    void oilTempChanged();
    void oilPressChanged();
    void engineTempChanged();
    void fuelAmountChanged();
    void rangeKmChanged();
    void turboChanged();
    void mileageChanged();
    void fuelReserveChanged();
    void avgConsumptionChanged();
    void instantConsumptionChanged();
    void throttleChanged();
    void outdoorTempChanged();
    void doorLeftStatusChanged();
    void doorRightStatusChanged();
    void hoodStatusChanged();
    void lightsStatusChanged();
    void trunkStatusChanged();
    void absWarningChanged();
    void tractionWarningChanged();
    void handbrakeChanged();
    void checkEngineChanged();

    void wheelSpeedsReceived(double lf, double rf, double lr, double rr);
    void clusterLightsReceived(bool leftBlinker, bool rightBlinker, bool highBeam, bool handbrake);

private:
    QThread m_workerThread;
    CanWorker *m_worker;

    int m_rpm = 0;
    int m_speed = 0;
    double m_oilTemp = 0.0;
    double m_oilPress = 0.0;
    double m_engineTemp = 0.0;
    double m_fuelAmount = 0.0;
    int m_rangeKm = 0;
    double m_turbo = 0.0;
    int m_mileage = 0;
    bool m_fuelReserve = false;
    double m_avgConsumption = 0.0;
    double m_instantConsumption = 0.0;
    double m_throttle = 0.0;
    double m_outdoorTemp = 0.0;
    bool m_doorLeft = false;
    bool m_doorRight = false;
    bool m_hoodOpen = false;
    bool m_headlightsActive = false;
    bool m_trunkOpen = false;
    bool m_absWarning = false;
    bool m_tractionWarning = false;
    bool m_handbrake = false;
    bool m_checkEngine = false;
};

#endif // CANBUSBACKEND_H
