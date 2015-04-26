part of dart_amqp_rpc.codec;

abstract class ProtobufRpcCodec implements RpcCodec {

  final ClassMirror _protobufMessageMirror = reflectClass(pb.GeneratedMessage);
  final Symbol _protobufCtor = new Symbol("fromBuffer");

  /**
   * Validate the list of [rpcMethods] that were extracted from the RPC interface.
   * The method should throw an [Exception] if it encounters an unsupported [RpcMethod]
   */
  void validateRpcMethods(List<RpcMethod> rpcMethods) {
    rpcMethods.forEach((RpcMethod method) {

      // Ensure that all RPC methods receive exactly one parameter extending GeneratedMessage
      if (method.argList.length != 1 || !method.argList.first.valueMirror.isAssignableTo(_protobufMessageMirror)) {
        throw new Exception("RPC method '${method.fqName}' should accept exactly one argument extending protobuf runtime-provided GeneratedMessage class");
      }

      // Ensure that return type also extends GeneratedMessage
      if (!method.returnType.isAssignableTo(_protobufMessageMirror)) {
        throw new Exception("RPC method '${method.fqName}' should return a value extending protobuf runtime-provided GeneratedMessage class");
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
    return new Future.value((params[0] as pb.GeneratedMessage).writeToBuffer());
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
      return new Future.value([
        rpcMethod.argList.first.valueMirror.newInstance(_protobufCtor, [ request ]).reflectee
      ]);
    } catch (e) {
      return new Future.error(e);
    }
  }

  /**
   * Evaluate the RPC method [response] and encode it to
   * a [Uint8List] to server as the amqp response message payload
   *
   * The [rpcMethod] is also provided for implementations that need access
   * to the method details (e.g. return type)
   *
   * This method should also handle cases where [response] completes
   * with an error and appropriately encode the error so it can be
   * unpacked and reported by the RPC client.
   *
   * This method is expected to work asynchronously and return a [Future] to
   * be completed with the marshaled data or an [Error] if encoding fails.
   */
  Future<Uint8List> encodeRpcResponse(RpcMethod rpcMethod, Future response) {
    return response
    .then((responseValue) => new Future.value((responseValue as pb.GeneratedMessage).writeToBuffer()))
    .catchError(encodeError);
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
      return new Future.value(
          rpcMethod.returnType.newInstance(_protobufCtor, [ response ]).reflectee
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