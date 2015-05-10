part of dart_amqp_rpc.examples.json;

class FibonacciClient extends RpcClient implements FibonacciInterface {

  FibonacciClient() : super.fromInterface(FibonacciInterface, namespace : "json");

  /**
   * Delegate any unknown [invocation] to [RpcClient].
   */
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}