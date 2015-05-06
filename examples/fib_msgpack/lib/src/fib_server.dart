part of dart_ampq_rpc.examples.msgpack;

// The RPC server
class FibonacciServer extends RpcServer implements FibonacciInterface {

  Future<FibValue> fib(FibQuery query) {
    int value = query.useRecursion
    ? utils.fibRecursive(query.number)
    : utils.fibIterative(query.number);

    return new Future.value(new FibValue(value));
  }

  FibonacciServer() : super.fromInterface(FibonacciInterface, namespace : "msgpack", rpcCodec : new MsgpackCodec());
}
