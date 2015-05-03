part of dart_ampq_rpc.examples.protobuf;

// The protobuf codec with custom error handling
class ProtobufCodec extends ProtobufRpcCodec {

  Future<Uint8List> encodeError(Object error) {
    RpcError errorMessage = new RpcError()
      ..message = error.toString();

    return new Future.value(errorMessage.writeToBuffer());
  }

  Future<Object> decodeError(Uint8List response) {
    return new Future.error(
        new RpcError.fromBuffer(response)
    );
  }

}
