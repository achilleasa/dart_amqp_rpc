part of dart_ampq_rpc.examples.protobuf;

// The RPC interface
abstract class FibonacciInterface {
  Future<FibValue> fib(FibQuery query);
}

