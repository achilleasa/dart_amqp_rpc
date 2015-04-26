library dart_amqp_rpc.tests.mocks;

import "package:logging/logging.dart";

bool initializedLogger = false;

void initLogger() {
  if (initializedLogger == true) {
    return;
  }
  initializedLogger = true;
  hierarchicalLoggingEnabled = true;
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print("[${rec.level.name}]\t[${rec.time}]\t[${rec.loggerName}]:\t${rec.message}");
  });
}
