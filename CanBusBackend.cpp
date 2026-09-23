#include "CanBusBackend.h"

#include <QDebug>
#include <QTimer>
#include <QProcess>
#include <QCoreApplication>
#include <QSettings>
#include <algorithm>
#include <cmath>

#ifdef Q_OS_LINUX
#include <unistd.h>
#include <cstring>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <linux/can.h>
#include <linux/can/raw.h>
#endif

// ============================================================================
// CAN WORKER IMPLEMENTATION
// ============================================================================

CanWorker::CanWorker(QObject *parent)
    : QObject(parent), m_running(false)
{
    QSettings settings("MiniDiDash", "MiniDiDash");
    m_totalConsumedLiters = settings.value("trip/consumedLiters", 0.0).toDouble();
    m_totalDistanceKm = settings.value("trip/distanceKm", 0.0).toDouble();
    m_currentLitersPerHundred = settings.value("trip/avgConsumption", 8.2).toDouble();

    m_rpmWatchdog = new QTimer(this);
    m_rpmWatchdog->setInterval(80);
    m_rpmWatchdog->setSingleShot(true);
    connect(m_rpmWatchdog, &QTimer::timeout, this, [this]() {
        emit rpmReceived(0);
    });

    if (m_totalDistanceKm > 0.5 && m_totalConsumedLiters > 0.05) {
        m_currentLitersPerHundred = (m_totalConsumedLiters / m_totalDistanceKm) * 100.0;
    } else {
        m_currentLitersPerHundred = 8.2;
    }

    m_lastValidMileage = settings.value("odometer/totalMileage", 276000).toInt();
    m_savedMileageToDisk = m_lastValidMileage;

    m_fuelTimer.start();
}

void CanWorker::startWorker()
{
    m_running = true;

    if (m_lastValidMileage > 0) {
        emit mileageReceived(m_lastValidMileage);
    }
    emit avgConsumptionReceived(m_currentLitersPerHundred);

#ifdef Q_OS_LINUX
    int socketCAN = socket(PF_CAN, SOCK_RAW, CAN_RAW);
    if (socketCAN < 0) {
        qWarning() << "SocketCAN FAIL!";
        return;
    }

    struct ifreq ifr;
    std::strcpy(ifr.ifr_name, "can0");
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
    tv.tv_usec = 200000;
    setsockopt(socketCAN, SOL_SOCKET, SO_RCVTIMEO, (const char*)&tv, sizeof(tv));

    struct can_frame frame;
    while (m_running) {
        int nbytes = read(socketCAN, &frame, sizeof(frame));
        if (nbytes > 0) {
            parseFrame(frame);
        }

        QCoreApplication::processEvents();
    }

    close(socketCAN);
#else
    qInfo() << "App run on Windows/MacOS - SocketCAN disabled";
#endif
}

void CanWorker::stopWorker()
{
    m_running = false;
    if (m_watchdogTimer) {
        m_watchdogTimer->stop();
    }
    if (m_rpmWatchdog) {
        m_rpmWatchdog->stop();
    }
}

void CanWorker::resetTripConsumption()
{
    m_totalConsumedLiters = 0.0;
    m_totalDistanceKm = 0.0;
    m_currentLitersPerHundred = 8.2;
    m_displayRange = -1.0;

    QSettings settings("MiniDiDash", "MiniDiDash");
    settings.setValue("trip/consumedLiters", 0.0);
    settings.setValue("trip/distanceKm", 0.0);
    settings.setValue("trip/avgConsumption", 8.2);

    emit avgConsumptionReceived(m_currentLitersPerHundred);
}

void CanWorker::onCanTimeout()
{
}

void CanWorker::onShutdownTimeout()
{
}

#ifdef Q_OS_LINUX
void CanWorker::parseFrame(const struct can_frame &frame)
{
    if (frame.can_id == 0x316 || frame.can_id == 0x153) {
        if (m_isSleeping) {
            m_isSleeping = false;
            emit sleepStateChanged(false);
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

    // RPM & Ignition State
    case 0x316: {
        if (frame.can_dlc >= 4) {
            uint8_t ignition_state = static_cast<uint8_t>(frame.data[0]);
            if (ignition_state == 0x00) {
                emit rpmReceived(0);
                if (m_rpmWatchdog) m_rpmWatchdog->stop();
            } else {
                uint8_t lsb = static_cast<uint8_t>(frame.data[2]);
                uint8_t msb = static_cast<uint8_t>(frame.data[3]);
                int raw_value = (static_cast<int>(msb) << 8) | lsb;
                double rpm_value = static_cast<double>(raw_value) * 0.15625;
                int rpm = static_cast<int>(rpm_value);
                if (rpm < 0) rpm = 0;
                if (rpm > 9000) rpm = 9000;

                emit rpmReceived(rpm);

                if (m_rpmWatchdog) {
                    m_rpmWatchdog->start();
                }
            }
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
            throttle_pct = std::clamp(throttle_pct, 0.0, 100.0);
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
                m_fuelTimer.restart();
                m_firstClickRecorded = true;
            } else {
                uint16_t deltaPulses = 0;
                if (currentFco >= m_lastFuelClick) {
                    deltaPulses = currentFco - m_lastFuelClick;
                } else {
                    deltaPulses = (65535 - m_lastFuelClick) + currentFco + 1;
                }

                if (deltaPulses > 0 && deltaPulses < 5000) {
                    qint64 dtMs = m_fuelTimer.restart();
                    if (dtMs <= 0 || dtMs > 1000) dtMs = 100;
                    m_lastFuelClick = currentFco;

                    double dtSec = static_cast<double>(dtMs) / 1000.0;
                    constexpr double LITERS_PER_PULSE = 1.0 / 64000.0;
                    double litersUsedNow = static_cast<double>(deltaPulses) * LITERS_PER_PULSE;
                    m_totalConsumedLiters += litersUsedNow;

                    double litersPerHour = (litersUsedNow / dtSec) * 3600.0;

                    double distanceKmNow = 0.0;
                    if (m_lastKnownSpeed > 2.0) {
                        distanceKmNow = (m_lastKnownSpeed / 3600.0) * dtSec;
                        m_totalDistanceKm += distanceKmNow;

                        double instantConsumption = (litersPerHour / m_lastKnownSpeed) * 100.0;
                        emit instantConsumptionReceived(std::clamp(instantConsumption, 0.5, 30.0));
                    } else {
                        emit instantConsumptionReceived(std::clamp(litersPerHour, 0.0, 15.0));
                    }

                    if (m_totalDistanceKm >= 0.2 && m_totalConsumedLiters > 0.02) {
                        m_currentLitersPerHundred = (m_totalConsumedLiters / m_totalDistanceKm) * 100.0;
                    }
                    emit avgConsumptionReceived(m_currentLitersPerHundred);

                    // Algorytm zasięgu (Dead Reckoning + korekta pływaka)
                    if (m_currentFuelLiters > 1.0) {
                        double safeConsumption = std::clamp(m_currentLitersPerHundred, 6.0, 11.0);
                        double tankEstimatedRange = (m_currentFuelLiters / safeConsumption) * 100.0;

                        if (m_displayRange < 0.0) {
                            m_displayRange = tankEstimatedRange;
                            m_lastDistanceForRange = m_totalDistanceKm;
                            m_lastFuelLevelForRefuel = m_currentFuelLiters;
                        }

                        if (m_currentFuelLiters > (m_lastFuelLevelForRefuel + 3.0)) {
                            m_displayRange = tankEstimatedRange;
                            m_lastFuelLevelForRefuel = m_currentFuelLiters;
                        }

                        double deltaDist = m_totalDistanceKm - m_lastDistanceForRange;
                        if (deltaDist > 0.0) {
                            m_lastDistanceForRange = m_totalDistanceKm;
                            m_displayRange -= deltaDist;

                            double driftError = tankEstimatedRange - m_displayRange;
                            m_displayRange += driftError * 0.005;
                        }

                        if (m_displayRange < 0.0) m_displayRange = 0.0;

                        int rangeInt = static_cast<int>(std::round(m_displayRange));
                        if (rangeInt != m_lastEmittedRange) {
                            m_lastEmittedRange = rangeInt;
                            emit rangeKmReceived(rangeInt);
                        }
                    } else {
                        m_displayRange = 0.0;
                        if (m_lastEmittedRange != 0) {
                            m_lastEmittedRange = 0;
                            emit rangeKmReceived(0);
                        }
                    }

                    if (++m_saveCounter >= 100) {
                        m_saveCounter = 0;
                        QSettings settings("MiniDiDash", "MiniDiDash");
                        settings.setValue("trip/consumedLiters", m_totalConsumedLiters);
                        settings.setValue("trip/distanceKm", m_totalDistanceKm);
                        settings.setValue("trip/avgConsumption", m_currentLitersPerHundred);
                    }
                }
            }
        }

        if (frame.can_dlc >= 5) {
            uint8_t oil_raw = static_cast<uint8_t>(frame.data[4]);
            if (oil_raw != 0x00 && oil_raw != 0xFF) {
                double oil_temp = static_cast<double>(oil_raw) - 48.0;
                emit oilTempReceived(oil_temp);
            }
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
        if (frame.can_dlc >= 2) {
            uint8_t byte1 = static_cast<uint8_t>(frame.data[1]);
            emit lightsStatusReceived((byte1 & 0x04) != 0);
        }
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

    // Mileage & Display BC
    case 0x61A: {
        if (frame.can_dlc >= 4) {
            uint32_t b_msb = static_cast<uint8_t>(frame.data[2]);
            uint32_t b_mid = static_cast<uint8_t>(frame.data[1]);
            uint32_t b_lsb = static_cast<uint8_t>(frame.data[3]);

            int mileage = static_cast<int>((b_msb << 16) | (b_mid << 8) | b_lsb);

            if (mileage >= 50000 && mileage <= 999999) {
                if (m_lastValidMileage > 0) {
                    if (mileage >= (m_lastValidMileage - 1) && mileage <= (m_lastValidMileage + 50)) {
                        m_lastValidMileage = mileage;
                        emit mileageReceived(mileage);

                        if (mileage - m_savedMileageToDisk >= 1) {
                            m_savedMileageToDisk = mileage;
                            QSettings settings("MiniDiDash", "MiniDiDash");
                            settings.setValue("odometer/totalMileage", mileage);
                        }
                    }
                } else {
                    m_lastValidMileage = mileage;
                    emit mileageReceived(mileage);
                }
            }
        }
        break;
    }

    // Instrument Cluster Lights & Indicators (Turn signals, ABS, Handbrake, etc.)
    case 0x61F: {
        if (frame.can_dlc >= 4) {
            // Byte 2: Lewy kierunkowskaz i długie światła
            uint8_t b2 = static_cast<uint8_t>(frame.data[2]);
            bool leftBlinker = (b2 & 0x40) != 0;
            bool highBeam    = (b2 & 0x80) != 0;

            // Byte 3: Ostrzeżenia i prawy kierunkowskaz
            uint8_t b3 = static_cast<uint8_t>(frame.data[3]);
            bool checkEngine  = (b3 & 0x01) != 0;
            bool handbrake    = (b3 & 0x02) != 0;
            bool absWarning   = (b3 & 0x04) != 0;
            bool rightBlinker = (b3 & 0x08) != 0;
            // bool oilWarning   = (b3 & 0x10) != 0;
            // bool emlWarning   = (b3 & 0x20) != 0;
            bool dscWarning   = (b3 & 0x40) != 0;
            // bool cruiseControl = (b3 & 0x80) != 0;

            emit clusterLightsReceived(leftBlinker, rightBlinker, highBeam, handbrake);
            emit engineMilStatusReceived(checkEngine);
            emit absWarningReceived(absWarning);
            emit tractionWarningReceived(dscWarning);
        }
        break;
    }

    default:
        break;
    }
}
#endif

// ============================================================================
// CANBUSBACKEND IMPLEMENTATION
// ============================================================================

CanBusBackend::CanBusBackend(QObject *parent)
    : QObject(parent),
    m_isSleeping(false),
    m_rpm(0), m_speed(0), m_oilTemp(0.0), m_oilPress(0.0),
    m_engineTemp(0.0), m_fuelAmount(0.0), m_rangeKm(0), m_turbo(0.0),
    m_mileage(0), m_fuelReserve(false), m_avgConsumption(8.2), m_instantConsumption(0.0),
    m_throttle(0.0), m_outdoorTemp(0.0), m_doorLeft(false),
    m_doorRight(false), m_hoodOpen(false), m_headlightsActive(false),
    m_leftBlinker(false), m_rightBlinker(false), m_highBeam(false),
    m_trunkOpen(false), m_absWarning(false), m_tractionWarning(false),
    m_handbrake(false), m_checkEngine(false)
{
    QSettings settings("MiniDiDash", "MiniDiDash");
    m_mileage = settings.value("odometer/totalMileage", 276000).toInt();
    m_avgConsumption = settings.value("trip/avgConsumption", 8.2).toDouble();

    m_worker = new CanWorker();
    m_worker->moveToThread(&m_workerThread);

    connect(&m_workerThread, &QThread::started, m_worker, &CanWorker::startWorker);
    connect(&m_workerThread, &QThread::finished, m_worker, &QObject::deleteLater);

    connect(m_worker, &CanWorker::sleepStateChanged, this, &CanBusBackend::setIsSleeping);
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
    connect(this, &CanBusBackend::requestResetTrip, m_worker, &CanWorker::resetTripConsumption);
    connect(m_worker, &CanWorker::wheelSpeedsReceived, this, &CanBusBackend::wheelSpeedsReceived);

    // Połączenie ramki kontrolek 0x61F ze slotem deski
    connect(m_worker, &CanWorker::clusterLightsReceived, this, &CanBusBackend::updateClusterLights);

    m_workerThread.start();
}

CanBusBackend::~CanBusBackend()
{
    if (m_worker) {
        m_worker->stopWorker();
    }
    m_workerThread.quit();
    m_workerThread.wait();
}

void CanBusBackend::resetTripConsumption()
{
    emit requestResetTrip();
}

void CanBusBackend::updateClusterLights(bool leftBlinker, bool rightBlinker, bool highBeam, bool handbrake)
{
    setLeftBlinker(leftBlinker);
    setRightBlinker(rightBlinker);
    setHighBeam(highBeam);
    setHandbrake(handbrake);
}

// Setters implementation
void CanBusBackend::setIsSleeping(bool s) { if (m_isSleeping != s) { m_isSleeping = s; emit isSleepingChanged(); } }
void CanBusBackend::setRpm(int r) { if (m_rpm != r) { m_rpm = r; emit rpmChanged(); } }
void CanBusBackend::setSpeed(int s) { if (m_speed != s) { m_speed = s; emit speedChanged(); } }
void CanBusBackend::setOilTemp(double t) { if (m_oilTemp != t) { m_oilTemp = t; emit oilTempChanged(); } }
void CanBusBackend::setOilPress(double p) { if (m_oilPress != p) { m_oilPress = p; emit oilPressChanged(); } }
void CanBusBackend::setEngineTemp(double e) { if (m_engineTemp != e) { m_engineTemp = e; emit engineTempChanged(); } }
void CanBusBackend::setFuelAmount(double f) { if (m_fuelAmount != f) { m_fuelAmount = f; emit fuelAmountChanged(); } }
void CanBusBackend::setRangeKm(int r) { if (m_rangeKm != r) { m_rangeKm = r; emit rangeKmChanged(); } }
void CanBusBackend::setTurbo(double tb) { if (m_turbo != tb) { m_turbo = tb; emit turboChanged(); } }
void CanBusBackend::setMileage(int m) { if (m_mileage != m) { m_mileage = m; emit mileageChanged(); } }
void CanBusBackend::setFuelReserve(bool fr) { if (m_fuelReserve != fr) { m_fuelReserve = fr; emit fuelReserveChanged(); } }
void CanBusBackend::setAvgConsumption(double ac) { if (m_avgConsumption != ac) { m_avgConsumption = ac; emit avgConsumptionChanged(); } }
void CanBusBackend::setInstantConsumption(double ic) { if (m_instantConsumption != ic) { m_instantConsumption = ic; emit instantConsumptionChanged(); } }
void CanBusBackend::setThrottle(double th) { if (m_throttle != th) { m_throttle = th; emit throttleChanged(); } }
void CanBusBackend::setOutdoorTemp(double ot) { if (m_outdoorTemp != ot) { m_outdoorTemp = ot; emit outdoorTempChanged(); } }
void CanBusBackend::setDoorLeft(bool dl) { if (m_doorLeft != dl) { m_doorLeft = dl; emit doorLeftStatusChanged(); } }
void CanBusBackend::setDoorRight(bool dr) { if (m_doorRight != dr) { m_doorRight = dr; emit doorRightStatusChanged(); } }
void CanBusBackend::setHoodOpen(bool ho) { if (m_hoodOpen != ho) { m_hoodOpen = ho; emit hoodStatusChanged(); } }
void CanBusBackend::setHeadlightsActive(bool ha) { if (m_headlightsActive != ha) { m_headlightsActive = ha; emit lightsStatusChanged(); } }

void CanBusBackend::setLeftBlinker(bool b)
{
    if (m_leftBlinker != b) {
        m_leftBlinker = b;
        emit leftBlinkerChanged();
    }
}

void CanBusBackend::setRightBlinker(bool b)
{
    if (m_rightBlinker != b) {
        m_rightBlinker = b;
        emit rightBlinkerChanged();
    }
}

void CanBusBackend::setHighBeam(bool hb)
{
    if (m_highBeam != hb) {
        m_highBeam = hb;
        emit highBeamChanged();
    }
}

void CanBusBackend::setTrunkOpen(bool to) { if (m_trunkOpen != to) { m_trunkOpen = to; emit trunkStatusChanged(); } }
void CanBusBackend::setAbsWarning(bool aw) { if (m_absWarning != aw) { m_absWarning = aw; emit absWarningChanged(); } }
void CanBusBackend::setTractionWarning(bool tw) { if (m_tractionWarning != tw) { m_tractionWarning = tw; emit tractionWarningChanged(); } }
void CanBusBackend::setHandbrake(bool hb) { if (m_handbrake != hb) { m_handbrake = hb; emit handbrakeChanged(); } }
void CanBusBackend::setCheckEngine(bool ce) { if (m_checkEngine != ce) { m_checkEngine = ce; emit checkEngineChanged(); } }
