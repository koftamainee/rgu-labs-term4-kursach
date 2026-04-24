#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "simulation_controller.hpp"

int main(int argc, char* argv[]) {
  QGuiApplication app(argc, argv);


  SimulationController controller;
  QQmlApplicationEngine engine;

  engine.rootContext()->setContextProperty("sim_controller", &controller);

  const QUrl url("qml/Main.qml");

  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreated, &app,
      [url](QObject* obj, const QUrl& objUrl) {
        if (!obj && url == objUrl) {
          QCoreApplication::exit(-1);
        }
      },
      Qt::QueuedConnection);

  engine.load(url);

  return app.exec();
}
