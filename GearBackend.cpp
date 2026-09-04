#include "GearBackend.h"
#include <chrono>
#include <thread>

#ifdef __linux__
#include <gpiod.h>
#endif

GearWorker::GearWorker(int gear1Pin, int gear2Pin, QObject *parent) : QThread(parent), m_gear1Pin(gear1Pin), m_gear2Pin(gear2Pin) {}

GearWorker::~GearWorker() {
    stop();
}

void GearWorker::stop() {
    m_running = false;
    wait();
}

void GearWorker::run() {
#ifdef __linux__
    struct gpiod_chip *chip = gpiod_chip_open("/dev/gpiochip4");
    if (!chip) {
        chip = gpiod_chip_open("/dev/gpiochip0");
    }
    if (!chip) return;

    struct gpiod_line_settings *settings = gpiod_line_settings_new();
    gpiod_line_settings_set_direction(settings, GPIOD_LINE_DIRECTION_INPUT);
    gpiod_line_settings_set_bias(settings, GPIOD_LINE_BIAS_PULL_UP);

    struct gpiod_line_config *line_cfg = gpiod_line_config_new();
    unsigned int offsets[2] = {
        static_cast<unsigned int>(m_gear1Pin),
        static_cast<unsigned int>(m_gear2Pin)
    };
    gpiod_line_config_add_line_settings(line_cfg, offsets, 2, settings);

    struct gpiod_request_config *req_cfg = gpiod_request_config_new();
    gpiod_request_config_set_consumer(req_cfg, "MiniDiDash_GearHall");

    struct gpiod_line_request *request = gpiod_chip_request_lines(chip, req_cfg, line_cfg);

    gpiod_request_config_free(req_cfg);
    gpiod_line_config_free(line_cfg);
    gpiod_line_settings_free(settings);

    if (!request) {
        gpiod_chip_close(chip);
        return;
    }

    QString lastGear = "N";

    while (m_running) {
        int val1 = gpiod_line_request_get_value(request, offsets[0]);
        int val2 = gpiod_line_request_get_value(request, offsets[1]);

        QString detectedGear = "N";
        if (val1 == GPIOD_LINE_VALUE_INACTIVE) {
            detectedGear = "1";
        } else if (val2 == GPIOD_LINE_VALUE_INACTIVE) {
            detectedGear = "2";
        }

        if (detectedGear != lastGear) {
            lastGear = detectedGear;
            emit gearChanged(detectedGear);
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(25));
    }
    gpiod_line_request_release(request);
    gpiod_chip_close(chip);

#else

    while (m_running) {
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }

#endif
}

GearBackend::GearBackend(QObject *parent) : QObject(parent) {
    m_worker = new GearWorker(17, 27, this);
    connect(m_worker, &GearWorker::gearChanged, this, &GearBackend::onGearUpdated);
    m_worker->start();
}

GearBackend::~GearBackend() {
    if (m_worker) {
        m_worker->stop();
    }
}

void GearBackend::onGearUpdated(const QString &gear) {
    if (m_currentGear != gear) {
        m_currentGear = gear;
        emit currentGearChanged();
    }
}
