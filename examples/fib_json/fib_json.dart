import "dart:async";
import "dart:io";
import "package:dart_amqp_rpc/dart_ampq_rpc.dart";
import "../shared/utils.dart" as utils;

// The RPC interface
abstract class FibonacciInterface {
  Future<int> fibRecursive(int n);

  Future<int> fibIterative(int n);
}

// The RPC server
class FibonacciServer extends RpcServer implements FibonacciInterface {

  Future<int> fibRecursive(int n) {
    return new Future.value(utils.fibRecursive(n));
  }

  Future<int> fibIterative(int n) {
    return new Future.value(utils.fibIterative(n));
  }

  FibonacciServer() : super.fromInterface(FibonacciInterface, methodPrefix : "json");
}

class FibonacciClient extends RpcClient implements FibonacciInterface {

  FibonacciClient() : super.fromInterface(FibonacciInterface, methodPrefix : "json");

  /**
   * Delegate any unknown [invocation] to [RpcClient].
   */
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // Allocate 5 servers and one client
  List<FibonacciServer> servers = new List<FibonacciServer>.generate(5, (_) => new FibonacciServer());
  FibonacciClient client = new FibonacciClient();

  // Connect all servers and then execute our test
  Future.wait(servers.map((FibonacciServer server) => server.connect()))
  .then((_) {

    // Execute in parallel:
    // - fibRecursive -> n: 1 to 10
    // - fibIterative -> n: 11 to 20
    List<Future> rpcCalls = new List<Future>.generate(20, (int index) {
      return index < 10
      ? client.fibRecursive(index + 1)
      : client.fibIterative(index + 1);
    });

    Future.wait(rpcCalls)
    .then((Iterable<int> results) {
      int index = 0;
      results.forEach((int res) {
        print(" [x] fib${index < 10 ? "Recursive" : "Iterative"}(${index + 1}) = ${res}");
        ++index;
      });
    }, onError : (e){
      print("Received error: ${e}");
    })
    .then((_) => Future.wait(servers.map((server) => server.close())))
    .then((_) => client.close())
    .then((_) => exit(0));
  });
}