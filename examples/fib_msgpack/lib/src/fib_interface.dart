part of dart_ampq_rpc.examples.msgpack;

// The RPC interface
abstract class FibonacciInterface {
  Future<FibValue> fib(FibQuery query);
}
