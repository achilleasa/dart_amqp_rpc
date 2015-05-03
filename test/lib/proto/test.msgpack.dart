library test.proto.msgpack;

import "package:msgpack/msgpack.dart";

class Invert extends Message {
  bool flag;

  Invert(this.flag);

  List toList() => [flag];

  static Invert fromList(List fields) => new Invert(fields[0]);
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