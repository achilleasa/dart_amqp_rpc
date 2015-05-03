part of dart_ampq_rpc.examples.msgpack;

class FibQuery extends Message {
  int number;
  bool useRecursion;

  FibQuery(this.number, this.useRecursion);

  List toList() => [number, useRecursion];

  static FibQuery fromList(List fields) => new FibQuery(fields[0], fields[1]);
}

class FibValue extends Message {
  int number;

  FibValue(this.number);

  List toList() => [number];

  static FibValue fromList(List fields) => new FibValue(fields[0]);
}


class RpcError extends Message {
  String message;

  RpcError(this.message);

  List toList() => [message];

  static RpcError fromList(List fields) => new RpcError(fields[0]);

  String toString() {
    return "RpcError: ${message}";
  }


}