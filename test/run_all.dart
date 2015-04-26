library dart_amqp_rpc.test;

import "lib/analyzer_test.dart" as analyzer;
import "lib/codec_test.dart" as codec;
import "lib/rpc_test.dart" as rpc;

void main(List<String> args) {

  // Check if we need to disable our loggers
  bool enableLogger = args.indexOf('--enable-logger') != -1;

  String allArgs = args.join(".");
  bool runAll = args.isEmpty || allArgs == '--enable-logger';

  if (runAll || (new RegExp("analyzer")).hasMatch(allArgs)) {
    analyzer.main(enableLogger : enableLogger);
  }

  if (runAll || (new RegExp("codec")).hasMatch(allArgs)) {
    codec.main(enableLogger : enableLogger);
  }

  if (runAll || (new RegExp("rpc")).hasMatch(allArgs)) {
    rpc.main(enableLogger : enableLogger);
  }
}