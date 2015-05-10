part of dart_amqp_rpc.examples.protobuf;

// The RPC interface
abstract class FibonacciInterface {
  Future<FibValue> fib(FibQuery query);
}

