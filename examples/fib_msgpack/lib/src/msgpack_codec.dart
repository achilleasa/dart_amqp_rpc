part of dart_ampq_rpc.examples.msgpack;

// The protobuf codec with custom error handling
class MsgpackCodec extends MsgpackRpcCodec {

  Future<Uint8List> encodeError(Object error) {
    RpcError errorMessage = new RpcError(error.toString());

    return new Future.value(new Uint8List.fromList(packer.packMessage(errorMessage)));
  }

  Future<Object> decodeError(Uint8List response) {
    return new Future.error(
        unpacker(response).unpackMessage(RpcError.fromList)
    );
  }

}