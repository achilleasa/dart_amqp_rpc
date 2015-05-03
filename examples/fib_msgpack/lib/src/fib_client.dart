part of dart_ampq_rpc.examples.msgpack;

class FibonacciClient extends RpcClient implements FibonacciInterface {

  FibonacciClient() : super.fromInterface(FibonacciInterface, methodPrefix : "msgpack", rpcCodec : new MsgpackCodec());

  /**
   * Delegate any unknown [invocation] to [RpcClient].
   */
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}