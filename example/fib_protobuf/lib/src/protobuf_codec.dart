part of dart_amqp_rpc.examples.protobuf;

// The protobuf codec with custom error handling
class ProtobufCodec extends ProtobufRpcCodec {

  /**
   * Encode a caught [error] while invoking [rpcMethod] with [rpcArgs] into a [Uint8List].
   * An optional stack [trace] may also be specified if available.
   */
  Future<Uint8List> encodeError(RpcMethod rpcMethod, List<Object> rpcArgs, Object error, {StackTrace trace}) {
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
