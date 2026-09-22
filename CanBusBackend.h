#ifndef CANBUSBACKEND_H
#define CANBUSBACKEND_H

#include <QObject>
#include <QThread>
#include <QElapsedTimer>
#include <QSettings>
#include <atomic>

class QTimer;
struct can_frame;

// ============================================================================
// CAN WORKER (Wątek roboczy SocketCAN)
// ============================================================================
class CanWorker : public QObject
{
    Q_OBJECT
public:
    explicit CanWorker(QObject *parent = nullptr);

public slots:
    void startWorker();
    void stopWorker();
    void resetTripConsumption();

private slots:
    void onCanTimeout();
    void onShutdownTimeout();

signals:
    void sleepStateChanged(bool sleeping);
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
#ifdef Q_OS_LINUX
    void parseFrame(const struct can_frame &frame);
#endif

    std::atomic<bool> m_running{false};
    QTimer *m_watchdogTimer = nullptr;
    QTimer *m_shutdownTimer = nullptr;
    QTimer *m_rpmWatchdog = nullptr;
    bool m_isSleeping = false;

    // FCO & Zużycie paliwa (0x545)
    bool m_firstClickRecorded = false;
    uint16_t m_lastFuelClick = 0;
    QElapsedTimer m_fuelTimer;
    int m_saveCounter = 0;

    double m_totalConsumedLiters = 0.0;
    double m_totalDistanceKm = 0.0;
    double m_currentLitersPerHundred = 8.2;
    double m_lastKnownSpeed = 0.0;
    double m_currentFuelLiters = 0.0;

    // Przebieg (0x61A)
    int m_lastValidMileage = 0;
    int m_savedMileageToDisk = 0;

    // Zasięg (Hybrydowy Dead Reckoning)
    double m_displayRange = -1.0;
    double m_lastDistanceForRange = 0.0;
    double m_lastFuelLevelForRefuel = 0.0;
    int m_lastEmittedRange = -1;
};

// ============================================================================
// BACKEND API FOR QML / MAIN THREAD
// ============================================================================
class CanBusBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isSleeping READ isSleeping NOTIFY isSleepingChanged)
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
    Q_PROPERTY(bool leftBlinker READ leftBlinker NOTIFY leftBlinkerChanged)
    Q_PROPERTY(bool rightBlinker READ rightBlinker NOTIFY rightBlinkerChanged)
    Q_PROPERTY(bool trunkOpen READ trunkOpen NOTIFY trunkStatusChanged)
    Q_PROPERTY(bool absWarning READ absWarning NOTIFY absWarningChanged)
    Q_PROPERTY(bool tractionWarning READ tractionWarning NOTIFY tractionWarningChanged)
    Q_PROPERTY(bool handbrake READ handbrake NOTIFY handbrakeChanged)
    Q_PROPERTY(bool checkEngine READ checkEngine NOTIFY checkEngineChanged)

public:
    explicit CanBusBackend(QObject *parent = nullptr);
    ~CanBusBackend() override;

    // Wywoływane z QML jako backend.resetTripConsumption()
    Q_INVOKABLE void resetTripConsumption();

    // Getters QML
    bool isSleeping() const { return m_isSleeping; }
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
    bool leftBlinker() const { return m_leftBlinker; }
    bool rightBlinker() const { return m_rightBlinker; }
    bool trunkOpen() const { return m_trunkOpen; }
    bool absWarning() const { return m_absWarning; }
    bool tractionWarning() const { return m_tractionWarning; }
    bool handbrake() const { return m_handbrake; }
    bool checkEngine() const { return m_checkEngine; }

public slots:
    void setIsSleeping(bool s);
    void setRpm(int r);
    void setSpeed(int s);
    void setOilTemp(double t);
    void setOilPress(double p);
    void setEngineTemp(double e);
    void setFuelAmount(double f);
    void setRangeKm(int r);
    void setTurbo(double tb);
    void setMileage(int m);
    void setFuelReserve(bool fr);
    void setAvgConsumption(double ac);
    void setInstantConsumption(double ic);
    void setThrottle(double th);
    void setOutdoorTemp(double ot);
    void setDoorLeft(bool dl);
    void setDoorRight(bool dr);
    void setHoodOpen(bool ho);
    void setHeadlightsActive(bool ha);
    void setLeftBlinker(bool b) {
        if (m_leftBlinker != b) {
            m_leftBlinker = b;
            emit leftBlinkerChanged();
        }

    }
    void setRightBlinker(bool b) {
        if (m_rightBlinker != b) {
            m_rightBlinker = b;
            emit rightBlinkerChanged();
        }
    }
    void setTrunkOpen(bool to);
    void setAbsWarning(bool aw);
    void setTractionWarning(bool tw);
    void setHandbrake(bool hb);
    void setCheckEngine(bool ce);

signals:
    void isSleepingChanged();
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
    void leftBlinkerChanged();
    void rightBlinkerChanged();

    // Sygnał wysyłany do wątku CanWorker
    void requestResetTrip();

private:
    QThread m_workerThread;
    CanWorker *m_worker;

    bool m_isSleeping = false;
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
    double m_avgConsumption = 8.2;
    double m_instantConsumption = 0.0;
    double m_throttle = 0.0;
    double m_outdoorTemp = 0.0;
    bool m_doorLeft = false;
    bool m_doorRight = false;
    bool m_hoodOpen = false;
    bool m_headlightsActive = false;
    bool m_leftBlinker = false;
    bool m_rightBlinker = false;
    bool m_trunkOpen = false;
    bool m_absWarning = false;
    bool m_tractionWarning = false;
    bool m_handbrake = false;
    bool m_checkEngine = false;
};

#endif // CANBUSBACKEND_H
