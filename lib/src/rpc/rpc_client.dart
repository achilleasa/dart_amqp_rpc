part of dart_amqp_rpc;

@proxy
abstract class RpcClient {

  final Uuid _uuidFactory = new Uuid();
  Map<Symbol, RpcMethod> _rpcSymbolToMethod = new Map<Symbol, RpcMethod>();
  Map<String, Queue> _rpcQueueMap = new Map<String, Queue>();
  final Map<String, Completer> _pendingOperations = new Map<String, Completer>();

  // The private queue that listens for RPC server responses
  Queue _replyQueue;

  // Client and connection details
  bool _usingExternalClient;
  Client _client;
  Completer _connected;

  // The codec to be used for marshalling/unmarshalling message data
  RpcCodec rpcCodec;

  // A prefix used for building the amqp queue name for each exposed rpc method
  String namespace;

  /**
   * Create a new [RpcClient] that serves as a dynamic proxy to the methods defined in [rpcInterface].
   * The class uses mirrors to detect all abstract methods from [rpcInterface] that return back
   * a [Future] and overrides [noSuchMethod] to automatically proxy the detected methods to
   * a RPC server.
   *
   * If an invalid [rpcInterface] type is supplied or the supplied [rpcInterface] does not
   * define any methods returning [Future], an [ArgumentError] will be thrown.
   *
   * An optional [namespace] named parameter may be specified in order to namespace the
   * exposed methods so as to avoid collisions with similarly named methods in other RPC
   * endpoints. The RPC endpoint queue name is built by joining together the [namespace]
   * and the method name using '.' as a delimiter. If no [namespace] is specified, the
   * default "rpc" will be used
   *
   * The [RpcClient] delegates all RPC message marshalling/unmarshalling to an external [RpcCodec].
   * A user-defined instance may be specified by the optional named parameter [rpcCodec]. If not
   * defined, the default [JsonRpcCodec] will be used.
   *
   * An optional [client] named parameter may be specified to force a specific [client] instance
   * to be used. If not specified, a client with default arguments will be instanciated.
   */
  RpcClient.fromInterface(Type rpcInterface, { String this.namespace : "rpc", RpcCodec this.rpcCodec, Client client }) {

    if (namespace == null || namespace.isEmpty) {
      namespace = "rpc";
    }

    // Create default client if not specified
    if (client == null) {
      _client = new Client();
      _usingExternalClient = false;
    } else {
      _client = client;
      _usingExternalClient = true;
    }

    // Use default JSON codec if not specified
    if (rpcCodec == null) {
      rpcCodec = new JsonRpcCodec();
    }

    // Detect and validate RPC methods
    _scanRpcMethods(rpcInterface);
  }

  void _scanRpcMethods(Type rpcInterface) {
    // Detect RPC methods
    List<RpcMethod> rpcMethodList = Analyzer.analyzeInterface(rpcInterface, namespace : namespace);
    if (rpcMethodList.isEmpty) {
      throw new ArgumentError("No RPC methods defined/implemented. Ensure that your RPC interface defines at least one method returning Future and that your RPC server implements it.");
    }

    // Ensure that methods are compatible with codec
    rpcCodec.validateRpcMethods(rpcMethodList);

    // Build RPC FQ-name to method map
    rpcMethodList.forEach((RpcMethod method) {
      _rpcSymbolToMethod[ method.symbolName ] = method;
    });

  }

  /**
   * Handle the RPC invocation response contained [message]. This method will
   * attempt to match the incoming message correlationId to one of the pending
   * RPC invocations and complete if (if matched) with the decoded [message]
   * response.
   */
  void _handleRpcResponse(AmqpMessage message) {
    // Ignore if the correlation id is unknown
    if (!_pendingOperations.containsKey(message.properties.corellationId)) {
      return;
    }

    // Complete pending request with the raw response payload
    _pendingOperations
    .remove(message.properties.corellationId)
    .complete(message.payload);
  }

  /**
   * Proxy [rpcMethod] invocation with the specified list of [arguments]
   * to the remote RPC server and return a [Future] to be completed either
   * with the remote version value or to fail if an error was detected.
   */
  Future _sendRpcRequest(RpcMethod rpcMethod, Iterable arguments) {
    return connect()
    .then((_) {

      // Encode payload using the requested codec
      return rpcCodec.encodeRpcRequest(rpcMethod, arguments)
      .then((Uint8List payload) {
        MessageProperties properties = new MessageProperties()
          ..replyTo = _replyQueue.name
          ..corellationId = _uuidFactory.v1();

        Completer completer = new Completer();
        _pendingOperations[ properties.corellationId ] = completer;
        _rpcQueueMap[rpcMethod.fqName].publish(payload, properties : properties);

        return completer.future
        .then((Uint8List messagePayload) {
          // Decode payload using the registered codec and complete the pending request
          return rpcCodec.decodeRpcResponse(rpcMethod, messagePayload);
        });
      });
    });
  }

  /**
   * Connect to the AMQP server and allocate a queue for each remote RPC method
   * as well as a private queue for receiving RPC responses.
   *
   * Returns a [Future] to be completed when the RPC client is ready for
   * proxying RPC requests.
   *
   * The client will lazilly invoke [connect] when the first RPC invocation is performed. However
   * end-users may manually invoke this method to ensure that the client is properly set up
   * before executing any RPC calls.
   */
  Future connect() {
    // Connected or already connecting
    if (_connected != null) {
      return _connected.future;
    }

    _connected = new Completer();

    // Bind a request queue for each method and one common private queue for the responses
    _client
    .channel()
    .then((Channel channel) => Future.wait(_rpcSymbolToMethod.values.map((RpcMethod method) => channel.queue(method.fqName))))
    .then((Iterable<Queue> allocatedQueues) {
      _rpcQueueMap = new Map<String, Queue>.fromIterables(
          _rpcSymbolToMethod.values.map((RpcMethod method) => method.fqName),
          allocatedQueues
      );

      // Allocate private queue for responses
      return allocatedQueues.first.channel.privateQueue();
    })
    .then((Queue privateQueue) => privateQueue.consume())
    .then((Consumer consumer) {
      // Store reply queue and bind response listener
      _replyQueue = consumer.queue;
      consumer.listen(_handleRpcResponse);

      _connected.complete();
    });

    return _connected.future;
  }

  /**
   * Shutdown the RPC client and return a [Future] to be completed when
   * the server has shutdown.
   *
   * This method will abort any pending RPC invocations and destroy the private
   * queue reserved for RPC responses.
   */
  Future close() {
    // Kill any pending responses
    _pendingOperations.forEach((_, Completer completer) => completer.completeError("RPC client shutting down"));
    _pendingOperations.clear();

    // delete private queue and shutdown the client only when using our own client
    return _replyQueue.delete()
    .then((_) => _usingExternalClient
    ? new Future.value()
    : _client.close()
    );
  }

  /**
   * This method is invoked whenever an unknown [invocation] is performed
   * on the RPC client instance. If the [invocation] points to one of the
   * supported RPC methods, then it will be automatically proxied to the
   * appropriate RPC server and a [Future] will be returned with the
   * method result.
   *
   * In all other cases, the invocation is delegated to the default Dart
   * implementation of [noSuchMethod].
   */
  noSuchMethod(Invocation invocation) {
    RpcMethod method = _rpcSymbolToMethod[ invocation.memberName ];

    // If this is not one of our supported rpc methods delegate to our parent's noSuchMethod()
    if (method == null) {
      return super.noSuchMethod(invocation);
    }

    // Execute RPC call
    return _sendRpcRequest(method, invocation.positionalArguments);
  }
}