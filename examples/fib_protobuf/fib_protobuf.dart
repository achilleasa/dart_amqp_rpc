import "dart:async";
import "dart:io";
import "dart:typed_data";
import "package:dart_amqp_rpc/dart_ampq_rpc.dart";
import "../shared/utils.dart" as utils;
import "lib/fib.pb.dart" as proto;

import "package:logging/logging.dart";

// The protobuf codec with custom error handling
class ProtobufCodec extends ProtobufRpcCodec {

  Future<Uint8List> encodeError(Object error) {
    proto.RpcError errorMessage = new proto.RpcError()
      ..message = error.toString();

    return new Future.value(errorMessage.writeToBuffer());
  }

  Future<Object> decodeError(Uint8List response) {
    return new Future.error(
        new proto.RpcError.fromBuffer(response)
    );
  }

}

// The RPC interface
abstract class FibonacciInterface {
  Future<proto.FibValue> fib(proto.FibQuery query);
}

// The RPC server
class FibonacciServer extends RpcServer implements FibonacciInterface {

  Future<proto.FibValue> fib(proto.FibQuery query) {
    proto.FibValue res = new proto.FibValue()
      ..number = query.useRecursion
    ? utils.fibRecursive(query.number)
    : utils.fibIterative(query.number);

    return new Future.value(res);
  }

  FibonacciServer() : super.fromInterface(FibonacciInterface, methodPrefix : "protobuf", rpcCodec : new ProtobufCodec());
}

class FibonacciClient extends RpcClient implements FibonacciInterface {

  FibonacciClient() : super.fromInterface(FibonacciInterface, methodPrefix : "protobuf", rpcCodec : new ProtobufCodec());

  /**
   * Delegate any unknown [invocation] to [RpcClient].
   */
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  hierarchicalLoggingEnabled = true;
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print("[${rec.level.name}]\t[${rec.time}]\t[${rec.loggerName}]:\t${rec.message}");
  });

  // Allocate 5 servers and one client
  List<FibonacciServer> servers = new List<FibonacciServer>.generate(1, (_) => new FibonacciServer());
  FibonacciClient client = new FibonacciClient();

  // Connect all servers and then execute our test
  Future.wait(servers.map((FibonacciServer server) => server.connect()))
  .then((_) {

    client.fib(new proto.FibQuery()
      ..number = -10)
    .then((proto.FibValue value) {
      print("Fib value: ${value.number}");
    }, onError : (e) {
      print("Received error: ${e}");
    })
    .then((_) => Future.wait(servers.map((server) => server.close())))
    .then((_) => client.close())
    .then((_) => exit(0));
  });
}