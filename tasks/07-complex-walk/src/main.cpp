#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <iostream>

#include "complex_walk_controller.hpp"

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);

    ComplexWalkController controller;
    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("walk_controller", &controller);

    engine.load(QUrl(QStringLiteral("qml/Main.qml")));
    if (engine.rootObjects().isEmpty()) {
        std::cout << "rootObjects is empty!" << std::endl;
        return -1;
    }

    return app.exec();
}
