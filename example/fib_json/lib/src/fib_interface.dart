part of dart_amqp_rpc.examples.json;

// The RPC interface
abstract class FibonacciInterface {
  Future<int> fibRecursive(int n);

  Future<int> fibIterative(int n);
}
