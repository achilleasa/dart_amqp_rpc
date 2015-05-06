part of dart_amqp_rpc.codec;

abstract class MsgpackRpcCodec implements RpcCodec {

  final Symbol fromListSymbol = new Symbol("fromList");
  final msgpack.Packer packer = new msgpack.Packer();
  final ClassMirror msgpackMessageMirror = reflectClass(msgpack.Message);

  /**
   * Create an [msgpack.Unpacker] for decoding [payload]
   */
  msgpack.Unpacker unpacker(Uint8List payload) {
    return new msgpack.Unpacker(payload.buffer);
  }

  /**
   * Validate the list of [rpcMethods] that were extracted from the RPC interface.
   * The method should throw an [Exception] if it encounters an unsupported [RpcMethod]
   */
  void validateRpcMethods(List<RpcMethod> rpcMethods) {
    rpcMethods.forEach((RpcMethod method) {

      // Ensure that all RPC methods receive exactly one parameter extending Message
      if (method.argList.length != 1 || !method.argList[0].valueMirror.isSubclassOf(msgpackMessageMirror)) {
        throw new Exception("RPC method '${method.fqName}' should accept exactly one argument extending msgpack runtime-provided Message class");
      }

      // Ensure that return type also extends Message
      if (!method.returnType.valueMirror.isSubclassOf(msgpackMessageMirror)) {
        throw new Exception("RPC method '${method.fqName}' should return a value extending msgpack runtime-provided Message class");
      }
    });
  }

  /**
   * Encode the list of RPC invocation [params] to an
   * [Uint8List] to serve as the amqp message payload.
   *
   * The [rpcMethod] is also provided for implementations that need access
   * to the method details (e.g. return type)
   *
   * This method is expected to work asynchronously and return a [Future] to
   * be completed with the marshaled data or an [Error] if encoding fails.
   */
  Future<Uint8List> encodeRpcRequest(RpcMethod rpcMethod, List<Object> params) {
    Uint8List packedData = new Uint8List.fromList(
        packer.packMessage((params[0] as msgpack.Message))
    );

    return new Future.value(packedData);
  }

  /**
   * Decode an incoming RPC [request] payload to a [List<Object>]
   * containing the RPC method invocation parameters.
   *
   * The [rpcMethod] is also provided for implementations that need access
   * to the method details (e.g. return type)
   *
   * This method is expected to work asynchronously and return a [Future] to
   * be completed with the unmarshaled list or an [Error] if decoding fails.
   */
  Future<List<Object>> decodeRpcRequest(RpcMethod rpcMethod, Uint8List request) {
    // Try decoding as the expected request message and return it back as a List so
    // we can attempt to invoke the RPC handling method
    try {
      msgpack.Unpacker unpacker = new msgpack.Unpacker(request.buffer);
      msgpack.Message requestMessage = unpacker.unpackMessage(
              (List fields) => rpcMethod.argList.first.valueMirror.invoke(fromListSymbol, [ fields ]).reflectee
      );
      return new Future.value([requestMessage]);
    } catch (e) {
      return new Future.error(e);
    }
  }

  /**
   * Encode the RPC method [response] into a [Uint8List] so that it can be
   * used as the amqp response message payload
   *
   * The [rpcMethod] is also provided for implementations that need access
   * to the method details (e.g. return type)
   *
   * This method is expected to work asynchronously and return a [Future] to
   * be completed with the marshaled data or an [Error] if encoding fails.
   */
  Future<Uint8List> encodeRpcResponse(RpcMethod rpcMethod, Object response) {
    Uint8List packedData = new Uint8List.fromList(
        packer.packMessage(response as msgpack.Message)
    );
    return new Future.value(packedData);
  }

  /**
   * Decode the [response] of a pending RPC call and return back
   * a [Future<Object>] to be completed with either with the RPC method
   * return value (in case of success) or with the error message
   * reported by the RPC server.
   *
   * The [rpcMethod] is also provided for implementations that need access
   * to the method details (e.g. return type)
   */
  Future<Object> decodeRpcResponse(RpcMethod rpcMethod, Uint8List response) {
    // Try decoding as the expected type. If that fails try decoding as an error
    // As a fallback throw an ArgumentError
    try {
      msgpack.Unpacker unpacker = new msgpack.Unpacker(response.buffer);
      return new Future.value(
        unpacker.unpackMessage(
                (List fields) => rpcMethod.returnType.valueMirror.invoke(fromListSymbol, [ fields ]).reflectee
        )
      );
    } catch (_) {
      try {
        return decodeError(response);
      } catch (_) {
        return new Future.error("Unable to decode server response for RPC method ${rpcMethod.fqName}");
      }
    }
  }
}