#include <QGuiApplication>
#include <QLoggingCategory>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtDebug>
#include <iostream>

#include "needle_controller.hpp"

int main(int argc, char* argv[]) {
  QGuiApplication app(argc, argv);

  qInstallMessageHandler([](QtMsgType type, const QMessageLogContext& ctx, const QString& msg) {
    const char* typeStr = "";
    switch (type) {
      case QtDebugMsg:
        typeStr = "DEBUG";
        break;
      case QtInfoMsg:
        typeStr = "INFO";
        break;
      case QtWarningMsg:
        typeStr = "WARNING";
        break;
      case QtCriticalMsg:
        typeStr = "CRITICAL";
        break;
      case QtFatalMsg:
        typeStr = "FATAL";
        break;
    }
    fprintf(stderr, "[%s] %s (%s:%d)\n", typeStr, msg.toLocal8Bit().constData(), ctx.file ? ctx.file : "", ctx.line);
  });

  NeedleController controller;
  QQmlApplicationEngine engine;

  engine.rootContext()->setContextProperty("needle_controller", &controller);

  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
      []() {
        fprintf(stderr, "[FATAL] QML object creation failed\n");
        QCoreApplication::exit(-1);
      },
      Qt::QueuedConnection);

  engine.load(QUrl(QStringLiteral("../../qml/Main.qml")));

  if (engine.rootObjects().isEmpty()) {
    fprintf(stderr, "[FATAL] rootObjects is empty — QML failed to load\n");
    return -1;
  }

  return app.exec();
}
