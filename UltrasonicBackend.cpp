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
    // RPi 5 używa chipu gpiochip4, starsze modele (RPi 4/3) gpiochip0
    struct gpiod_chip *chip = gpiod_chip_open("/dev/gpiochip4");
    if (!chip) {
        chip = gpiod_chip_open("/dev/gpiochip0");
    }
    if (!chip) return;

    // 1. Konfiguracja pinu TRIG (OUTPUT)
    struct gpiod_line_settings *settings_trig = gpiod_line_settings_new();
    gpiod_line_settings_set_direction(settings_trig, GPIOD_LINE_DIRECTION_OUTPUT);
    gpiod_line_settings_set_output_value(settings_trig, GPIOD_LINE_VALUE_INACTIVE);

    // 2. Konfiguracja pinu ECHO (INPUT)
    struct gpiod_line_settings *settings_echo = gpiod_line_settings_new();
    gpiod_line_settings_set_direction(settings_echo, GPIOD_LINE_DIRECTION_INPUT);

    // 3. Konfiguracja linii w line_config
    struct gpiod_line_config *line_cfg = gpiod_line_config_new();
    unsigned int trig_offset = static_cast<unsigned int>(m_trigPin);
    unsigned int echo_offset = static_cast<unsigned int>(m_echoPin);

    gpiod_line_config_add_line_settings(line_cfg, &trig_offset, 1, settings_trig);
    gpiod_line_config_add_line_settings(line_cfg, &echo_offset, 1, settings_echo);

    // 4. Utworzenie requestu
    struct gpiod_request_config *req_cfg = gpiod_request_config_new();
    gpiod_request_config_set_consumer(req_cfg, "MiniDiDash_Ultrasonic");

    struct gpiod_line_request *request = gpiod_chip_request_lines(chip, req_cfg, line_cfg);

    // Zwolnienie tymczasowych struktur konfiguracyjnych
    gpiod_request_config_free(req_cfg);
    gpiod_line_config_free(line_cfg);
    gpiod_line_settings_free(settings_trig);
    gpiod_line_settings_free(settings_echo);

    if (!request) {
        gpiod_chip_close(chip);
        return;
    }

    std::this_thread::sleep_for(std::chrono::milliseconds(300));

    while (m_running) {
        // Impuls wyzwalający TRIG (10 µs)
        gpiod_line_request_set_value(request, trig_offset, GPIOD_LINE_VALUE_ACTIVE);
        std::this_thread::sleep_for(std::chrono::microseconds(10));
        gpiod_line_request_set_value(request, trig_offset, GPIOD_LINE_VALUE_INACTIVE);

        auto t_start = std::chrono::steady_clock::now();
        auto p_start = t_start;
        auto p_end = t_start;

        // Oczekiwanie na stan wysoki (poczatek impulsu Echo) z limitem 30 ms
        while (gpiod_line_request_get_value(request, echo_offset) == GPIOD_LINE_VALUE_INACTIVE && m_running) {
            p_start = std::chrono::steady_clock::now();
            if (std::chrono::duration<double>(p_start - t_start).count() > 0.03) {
                break;
            }
        }

        // Oczekiwanie na koniec impulsu Echo
        auto t_echo = std::chrono::steady_clock::now();
        while (gpiod_line_request_get_value(request, echo_offset) == GPIOD_LINE_VALUE_ACTIVE && m_running) {
            p_end = std::chrono::steady_clock::now();
            if (std::chrono::duration<double>(p_end - t_echo).count() > 0.03) {
                break;
            }
        }

        double duration = std::chrono::duration<double>(p_end - p_start).count();

        // Przeliczenie odległości (prędkość dźwięku ~343 m/s)
        if (duration > 0.00005 && duration < 0.03) {
            double dist = duration * 17165.0;
            emit distanceUpdated(dist);
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(80));
    }

    gpiod_line_request_release(request);
    gpiod_chip_close(chip);

#else
    // Symulacja pod Windows
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
