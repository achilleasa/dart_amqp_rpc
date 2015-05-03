part of dart_ampq_rpc.examples.protobuf;

// The protobuf codec with custom error handling
class ProtobufCodec extends ProtobufRpcCodec {

  /**
   * Encode a caught [error] into a [Uint8List]
   */
  Future<Uint8List> encodeError(Object error) {
    RpcError errorMessage = new RpcError()
      ..message = error.toString();

    return new Future.value(errorMessage.writeToBuffer());
  }

  /**
   * Decode a [response] containing a caught error message and
   * return back a failed [Future] with the error message
   */
  Future<Object> decodeError(Uint8List response) {
    return new Future.error(
        new RpcError.fromBuffer(response)
    );
  }

}
