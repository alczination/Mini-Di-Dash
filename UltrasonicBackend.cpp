#include "UltrasonicBackend.h"
#include <chrono>
#include <thread>
#include <cmath>

#ifdef __linux__
#include <gpiod.h>
#endif

UltrasonicWorker::UltrasonicWorker(int trigPin, int echoPin, QObject *parent)
    : QThread(parent), m_trigPin(trigPin), m_echoPin(echoPin) {}

UltrasonicWorker::~UltrasonicWorker() {
    stop();
}

void UltrasonicWorker::stop() {
    m_running = false;
    wait();
}

void UltrasonicWorker::run() {
#ifdef __linux__
    // Sprzętowy odczyt GPIO na Raspberry Pi
    struct gpiod_chip *chip = gpiod_chip_open_by_number(0);
    if (!chip) return;

    struct gpiod_line *line_trig = gpiod_chip_get_line(chip, m_trigPin);
    struct gpiod_line *line_echo = gpiod_chip_get_line(chip, m_echoPin);

    gpiod_line_request_output(line_trig, "ultrasonic_trig", 0);
    gpiod_line_request_input(line_echo, "ultrasonic_echo");

    std::this_thread::sleep_for(std::chrono::milliseconds(300));

    while (m_running) {
        gpiod_line_set_value(line_trig, 1);
        std::this_thread::sleep_for(std::chrono::microseconds(10));
        gpiod_line_set_value(line_trig, 0);

        auto t_start = std::chrono::steady_clock::now();
        auto p_start = t_start;
        auto p_end = t_start;

        while (gpiod_line_get_value(line_echo) == 0 && m_running) {
            p_start = std::chrono::steady_clock::now();
            if (std::chrono::duration<double>(p_start - t_start).count() > 0.03) {
                break;
            }
        }

        auto t_echo = std::chrono::steady_clock::now();
        while (gpiod_line_get_value(line_echo) == 1 && m_running) {
            p_end = std::chrono::steady_clock::now();
            if (std::chrono::duration<double>(p_end - t_echo).count() > 0.03) {
                break;
            }
        }

        double duration = std::chrono::duration<double>(p_end - p_start).count();

        if (duration > 0.00005 && duration < 0.03) {
            double dist = duration * 17165.0;
            emit distanceUpdated(dist);
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(80));
    }

    gpiod_line_release(line_trig);
    gpiod_line_release(line_echo);
    gpiod_chip_close(chip);

#else
    // Symulacja pod Windows (pozwala na kompilację i testowanie QML)
    double simulatedDist = 140.0;
    double step = -2.5;

    while (m_running) {
        simulatedDist += step;
        if (simulatedDist <= 15.0) {
            simulatedDist = 15.0;
            step = 2.5;
        } else if (simulatedDist >= 140.0) {
            simulatedDist = 140.0;
            step = -2.5;
        }

        emit distanceUpdated(simulatedDist);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
#endif
}

UltrasonicBackend::UltrasonicBackend(QObject *parent) : QObject(parent) {
    m_worker = new UltrasonicWorker(4, 17, this);
    connect(m_worker, &UltrasonicWorker::distanceUpdated, this, &UltrasonicBackend::onDistanceUpdated);
    m_worker->start();
}

UltrasonicBackend::~UltrasonicBackend() {
    if (m_worker) {
        m_worker->stop();
    }
}

void UltrasonicBackend::onDistanceUpdated(double dist) {
    if (std::abs(m_distance - dist) > 0.2) {
        m_distance = dist;
        emit distanceChanged();
    }
}
