#pragma once

#include <QObject>
#include <QSerialPort>
#include <QByteArray>
#include <QTimer>

class GearSensorReceiver : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentGear READ currentGear NOTIFY currentGearChanged)
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY isConnectedChanged)

public:
    explicit GearSensorReceiver(QObject *parent = nullptr);
    ~GearSensorReceiver();

    QString currentGear() const { return m_currentGear; }
    bool isConnected() const { return m_serialPort->isOpen(); }

signals:
    void currentGearChanged(const QString &gear);
    void isConnectedChanged(bool connected);

private slots:
    void handleReadyRead();
    void handleError(QSerialPort::SerialPortError error);
    void attemptConnection();

private:
    QSerialPort *m_serialPort;
    QTimer *m_reconnectTimer;
    QByteArray m_readBuffer;
    QString m_currentGear = "N";
    const QString m_portName = "/dev/ttyMiniGear"; // Lub np. "COM3" / "/dev/ttyUSB0"
};
