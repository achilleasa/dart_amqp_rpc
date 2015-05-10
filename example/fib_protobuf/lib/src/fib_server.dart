part of dart_ampq_rpc.examples.protobuf;

// The RPC server
class FibonacciServer extends RpcServer implements FibonacciInterface {

  Future<FibValue> fib(FibQuery query) {
    FibValue result = new FibValue()
      ..number = query.useRecursion
        ? utils.fibRecursive(query.number)
        : utils.fibIterative(query.number);

    return new Future.value(result);
  }

  FibonacciServer() : super.fromInterface(FibonacciInterface, namespace : "protobuf", rpcCodec : new ProtobufCodec());
}
