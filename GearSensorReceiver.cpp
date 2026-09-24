#include "GearSensorReceiver.h"
#include <QDebug>

GearSensorReceiver::GearSensorReceiver(QObject *parent)
    : QObject(parent),
    m_serialPort(new QSerialPort(this)),
    m_reconnectTimer(new QTimer(this))
{
    connect(m_serialPort, &QSerialPort::readyRead, this, &GearSensorReceiver::handleReadyRead);
    connect(m_serialPort, &QSerialPort::errorOccurred, this, &GearSensorReceiver::handleError);
    connect(m_reconnectTimer, &QTimer::timeout, this, &GearSensorReceiver::attemptConnection);
    m_reconnectTimer->start(2000);

    attemptConnection();
}

GearSensorReceiver::~GearSensorReceiver()
{
    if (m_serialPort->isOpen()) {
        m_serialPort->close();
    }
}

void GearSensorReceiver::attemptConnection()
{
    if (m_serialPort->isOpen()) return;

    m_serialPort->setPortName(m_portName);
    m_serialPort->setBaudRate(QSerialPort::Baud115200);
    m_serialPort->setDataBits(QSerialPort::Data8);
    m_serialPort->setParity(QSerialPort::NoParity);
    m_serialPort->setStopBits(QSerialPort::OneStop);
    m_serialPort->setFlowControl(QSerialPort::NoFlowControl);

    if (m_serialPort->open(QIODevice::ReadOnly)) {
        qInfo() << "[GearSensor] Połączono z portem:" << m_portName;
        emit isConnectedChanged(true);
    }
}

void GearSensorReceiver::handleReadyRead()
{
    m_readBuffer.append(m_serialPort->readAll());

    while (m_readBuffer.contains('\n')) {
        int newlineIndex = m_readBuffer.indexOf('\n');
        QByteArray line = m_readBuffer.left(newlineIndex).trimmed();
        m_readBuffer.remove(0, newlineIndex + 1);

        QString data = QString::fromUtf8(line);
        if (data.startsWith("GEAR:")) {
            QString gear = data.mid(5).trimmed();
            if (m_currentGear != gear) {
                m_currentGear = gear;
                emit currentGearChanged(m_currentGear);
            }
        }
    }
}

void GearSensorReceiver::handleError(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::ResourceError || error == QSerialPort::DeviceNotFoundError) {
        qWarning() << "[GearSensor] Błąd portu lub odłączenie urządzenia:" << m_serialPort->errorString();
        m_serialPort->close();
        emit isConnectedChanged(false);
    }
}
