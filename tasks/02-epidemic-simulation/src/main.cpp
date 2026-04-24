#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <iostream>

#include "simulation_controller.hpp"

int main(int argc, char* argv[]) {
  QGuiApplication app(argc, argv);

  SimulationController sim_controller;
  QQmlApplicationEngine engine;

  engine.rootContext()->setContextProperty("sim_controller", &sim_controller);

  engine.load(QUrl(QStringLiteral("qml/Main.qml")));
  if (engine.rootObjects().isEmpty()) {
    std::cout << "rootObjects is empty!" << std::endl;
    return -1;
  }

  return app.exec();
}
