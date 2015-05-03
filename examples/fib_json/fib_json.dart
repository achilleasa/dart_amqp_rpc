import "dart:async";
import "dart:io";
import "package:logging/logging.dart";
import "lib/rpc.dart" as rpc;
import "../shared/options.dart" as options;

void main(List<String> args) {
  // Parse command line
  options.Options opt = options.parse("fib_json.dart", args);

  // Enable hierarchical logging and disable RPC library output if no
  // verbose output is required
  hierarchicalLoggingEnabled = true;
  Logger logger = new Logger("main");
  new Logger("dart_amqp")
    ..level = opt.verbose
      ? Level.INFO
      : Level.OFF;

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print("[${rec.level.name}]\t[${rec.time}]\t[${rec.loggerName}]:\t${rec.message}");
  });

  logger.info("Running RPC fib() with args [${opt.from} to ${opt.to}] using ${opt.numServers} server${opt.numServers != 1 ? "s" : ""}.");
  logger.info("Invoke with -h parameter for additional options...");

  // Allocate servers and one client
  List<rpc.FibonacciServer> servers = new List<rpc.FibonacciServer>.generate(opt.numServers, (_) => new rpc.FibonacciServer());
  rpc.FibonacciClient client = new rpc.FibonacciClient();

  // Connect all servers and then execute our requests
  Future.wait(servers.map((rpc.FibonacciServer server) => server.connect()))
  .then((_) {
    Completer done = new Completer();
    int inc = opt.from <= opt.to ? 1 : -1;
    int remainingResponses = 0;
    for (int number = opt.from; number <= opt.to; number += inc) {

      ++remainingResponses;

      Future request = number % 2 == 0
        ? client.fibRecursive(number)
        : client.fibIterative(number);

      request
      .then((int result) {
        logger.info("[x] fib(${number}) = ${result}");
        if (--remainingResponses == 0) {
          done.complete();
        }
      }, onError : (e) {
        logger.severe("[x] fib(${number}) = ${e}");

        if (--remainingResponses == 0) {
          done.complete();
        }
      });
    }

    return done.future;
  })
  .then((_) => Future.wait(servers.map((server) => server.close())))
  .then((_) => client.close())
  .then((_) => exit(0));
}