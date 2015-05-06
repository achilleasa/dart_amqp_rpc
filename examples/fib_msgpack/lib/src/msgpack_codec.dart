part of dart_ampq_rpc.examples.msgpack;

// The protobuf codec with custom error handling
class MsgpackCodec extends MsgpackRpcCodec {

  /**
   * Encode a caught [error] while invoking [rpcMethod] with [rpcArgs] into a [Uint8List].
   * An optional stack [trace] may also be specified if available.
   */
  Future<Uint8List> encodeError(RpcMethod rpcMethod, List<Object> rpcArgs, Object error, {StackTrace trace}) {
    RpcError errorMessage = new RpcError(error.toString());

    return new Future.value(new Uint8List.fromList(packer.packMessage(errorMessage)));
  }

  /**
   * Decode a [response] containing a caught error message and
   * return back a failed [Future] with the error message
   */
  Future<Object> decodeError(Uint8List response) {
    return new Future.error(
        unpacker(response).unpackMessage(RpcError.fromList)
    );
  }

}