#ifndef GEARSENSOR_H
#define GEARSENSOR_H

#pragma once
#include <QObject>
#include <QThread>
// #include <gpiod.h>

class GearSensor : public QObject {
    Q_OBJECT
    Q_PROPERTY(int currentGear READ currentGear NOTIFY gearChanged)

public:
    explicit GearSensor(QObject *parent = nullptr);
    ~GearSensor();
    int currentGear() const { return m_currentGear; }

signals:
    void gearChanged(int gear);

public slots:
    void pollSensor();

private:
    int m_currentGear = 0;
    struct gpiod_chip *chip = nullptr;
    struct gpiod_line *line = nullptr;
};

#endif // GEARSENSOR_H
