#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QQmlContext>

#include "CanBusBackend.h"
#include "UltrasonicBackend.h"

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QCoreApplication::setOrganizationDomain("MiniDiDash");
    QCoreApplication::setApplicationName("MiniDiDash");

    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    CanBusBackend canBackend;
    UltrasonicBackend ultrasonicBackend;
    engine.rootContext()->setContextProperty("canBusBackend", &canBackend);
    engine.rootContext()->setContextProperty("ultrasonicBackend", &ultrasonicBackend);

    const QUrl url(QStringLiteral("qrc:/MiniDashboard/Main.qml"));
    engine.load(url);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url, &canBackend](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl) {
                             QCoreApplication::exit(-1);
                         }

                         QQuickWindow *window = qobject_cast<QQuickWindow*>(obj);
                         if (window) {
                             window->setWidth(720);
                             window->setHeight(720);

                             // Reagowanie na zmianę stanu uśpienia z backendu CAN
                             QObject::connect(&canBackend, &CanBusBackend::isSleepingChanged, window, [window, &canBackend]() {
                                 if (canBackend.isSleeping()) {
                                     // Ukrycie okna wstrzymuje renderowanie sceny QML i uwalnia GPU
                                     window->hide();
                                 } else {
                                     // Przywrócenie widoczności i renderowania
                                     window->show();
                                 }
                             });
                         }
                     }, Qt::QueuedConnection);

    return app.exec();
}
