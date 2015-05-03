part of dart_amqp_rpc.analyzer;

class RpcMethod {

  // The method symbol name
  Symbol symbolName;

  // The stringified fully qualified name of the method
  String fqName;

  // The method implementation
  ClosureMirror implementation;

  // The rpc method arguments
  List<RpcArgument> argList;

  // The method eventual return type after the Future is evaluated
  RpcArgument returnType;
}
