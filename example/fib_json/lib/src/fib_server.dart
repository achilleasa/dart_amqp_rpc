part of dart_amqp_rpc.examples.json;

// The RPC server
class FibonacciServer extends RpcServer implements FibonacciInterface {

  Future<int> fibRecursive(int n) {
    return new Future.value(utils.fibRecursive(n));
  }

  Future<int> fibIterative(int n) {
    return new Future.value(utils.fibIterative(n));
  }

  FibonacciServer() : super.fromInterface(FibonacciInterface, namespace : "json");
}