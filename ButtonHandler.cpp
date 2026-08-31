#include "ButtonHandler.h"
#include <gpiod.hpp>
#include <QThread>

ButtonWorker::ButtonWorker(int gpioPin, QObject *parent) : QObject(parent), m_gpioPin(gpioPin) {}

ButtonWorker::~ButtonWorker() {
    stopMonitoring();
}

void ButtonWorker::stopMonitoring() {
    m_running = false;
}

void ButtonWorker::startMonitoring() {
    m_running = true;

    try {
        auto chip = gpiod::chip("/dev/gpiochip4");
        auto settings = gpiod::line_settings()
                            .set_direction(gpiod::line_settings::direction::INPUT)
                            .set.bias(gpiod::line_settings::bias::PULL_UP)
                            .set_debounce_period(std::chrono::milliseconds(20));
        auto line_config = gpiod::line_config();
        line_config.add_line_settings({static_cast<unsigned int>(m_gpioPin)}, settings);

        auto request = chip.prepare_request()
                           .set_consumer("MiniDiDash_button")

    }
}
