part of dart_amqp_rpc.analyzer;

class RpcArgument {
  final String name;
  final ClassMirror valueMirror;

  RpcArgument(this.name, this.valueMirror);
}