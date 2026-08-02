#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QQmlContext>
#include "CanBusBackend.h"

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    CanBusBackend canBackend;
    engine.rootContext()->setContextProperty("canBusBackend", &canBackend);

    const QUrl url(QStringLiteral("qrc:/MiniDashboard/Main.qml"));
    engine.load(url);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl) {
                             QCoreApplication::exit(-1);
                         }

                         QQuickWindow *window = qobject_cast<QQuickWindow*>(obj);
                         if (window) {
                             window->setWidth(720);
                             window->setHeight(720);
                             // window->setMinimumSize(QSize(720, 720));
                         }
                     }, Qt::QueuedConnection);

    return app.exec();
}
