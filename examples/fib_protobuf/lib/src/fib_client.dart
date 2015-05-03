part of dart_ampq_rpc.examples.protobuf;

class FibonacciClient extends RpcClient implements FibonacciInterface {

  FibonacciClient() : super.fromInterface(FibonacciInterface, methodPrefix : "protobuf", rpcCodec : new ProtobufCodec());

  /**
   * Delegate any unknown [invocation] to [RpcClient].
   */
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}