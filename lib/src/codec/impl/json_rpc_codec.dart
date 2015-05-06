part of dart_amqp_rpc.codec;

class JsonRpcCodec implements RpcCodec {

  /**
   * Validate the list of [rpcMethods] that were extracted from the RPC interface.
   * The method should throw an [Exception] if it encounters an unsupported [RpcMethod]
   */
  void validateRpcMethods(List<RpcMethod> rpcMethods) {
    // No-op
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
    return new Future.value(
        new Uint8List.fromList(JSON.encode(params).codeUnits)
    );
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
    return new Future.value(
        JSON.decode(new String.fromCharCodes(request))
    );
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
    return new Future<Uint8List>.value(
        new Uint8List.fromList(JSON.encode(response).codeUnits)
    );
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
    dynamic responseValue = JSON.decode(new String.fromCharCodes(response));
    if (responseValue is Map && responseValue.containsKey("error")) {
      return decodeError(response);
    }

    return new Future.value(responseValue);
  }

  /**
   * Encode a caught [error] while invoking [rpcMethod] with [rpcArgs] into a [Uint8List].
   * An optional stack [trace] may also be specified if available.
   */
  Future<Uint8List> encodeError(RpcMethod rpcMethod, List<Object> rpcArgs, Object error, {StackTrace trace}) {
    return new Future<Uint8List>.value(
        new Uint8List.fromList(
            JSON.encode({"error" : error.toString()}).codeUnits
        )
    );
  }

  /**
   * Decode a [response] containing a caught error message and
   * return back a failed [Future] with the error message
   */
  Future<Object> decodeError(Uint8List response) {
    Map responseValue = JSON.decode(new String.fromCharCodes(response));
    return new Future.error(responseValue["error"]);
  }
}