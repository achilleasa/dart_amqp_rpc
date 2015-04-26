part of dart_amqp_rpc;

abstract class RpcServer {

  // A map of amqp queue names to a RPC methods implemented by the server
  final Map<String, RpcMethod> _rpcNameToMethod = new Map<String, RpcMethod>();
  final List<Consumer> _rpcConsumers = [];

  // Client and connection details
  bool _usingExternalClient;
  Client _client;
  Completer _connected;

  // The codec to be used for marshalling/unmarshalling message data
  RpcCodec rpcCodec;

  // A prefix used for building the amqp queue name for each exposed rpc method
  String methodPrefix;

  /**
   * Create a new [RpcServer] instance exposing the methods defined in [rpcInterface]
   * as RPC endpoints. This class uses mirrors to identify which methods from [rpcInterface]
   * are actually defined in the current class instance and expose them.
   *
   * If an invalid [rpcInterface] type is supplied or the current class instance does not
   * implement any of the methods defined in [rpcInterface] an [ArgumentError] will be thrown.
   *
   * An optional [methodPrefix] named parameter may be specified in order to namespace the
   * exposed methods so as to avoid collisions with similarly named methods in other RPC
   * endpoints. The RPC endpoint queue name is built by joining together the [methodPrefix]
   * and the method name using '.' as a delimiter. If no [methodPrefix] is specified, the
   * default "rpc" will be used.
   *
   * The [RpcServer] delegates all RPC message marshalling/unmarshalling to an external [RpcCodec].
   * A user-defined instance may be specified by the optional named parameter [rpcCodec]. If not
   * defined, the default [JsonRpcCodec] will be used.
   *
   * An optional [client] named parameter may be specified to force a specific [client] instance
   * to be used. If not specified, a client with default arguments will be instanciated.
   */
  RpcServer.fromInterface(Type rpcInterface, { String this.methodPrefix : "rpc", RpcCodec this.rpcCodec, Client client }) {

    if (methodPrefix == null || methodPrefix.isEmpty) {
      methodPrefix = "rpc";
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
    List<RpcMethod> rpcMethodList = Analyzer.analyzeInterface(rpcInterface, methodPrefix : methodPrefix, implementation : this);
    if (rpcMethodList.isEmpty) {
      throw new ArgumentError("No RPC methods defined/implemented. Ensure that your RPC interface defines at least one method returning Future and that your RPC server implements it.");
    }

    // Ensure that methods are compatible with codec
    rpcCodec.validateRpcMethods(rpcMethodList);

    // Build RPC FQ-name to method map
    rpcMethodList.forEach((RpcMethod method) {
      _rpcNameToMethod[ method.fqName ] = method;
    });
  }

  /**
   * Connect to the AMQP server and allocate a queue for each exposed RPC method.
   * Returns a [Future] to be completed when the RPC server is ready for
   * processing incoming requests.
   */
  Future connect() {
    // Connected or already connecting
    if (_connected != null) {
      return _connected.future;
    }

    _connected = new Completer();

    // Bind a request queue for each method and add a consumer for each
    _client
    .channel()
    .then((Channel channel) => channel.qos(0, 1))
    .then((Channel channel) => Future.wait(_rpcNameToMethod.keys.map((String queueName) => channel.queue(queueName))))
    .then((Iterable<Queue> methodQueues) => Future.wait(methodQueues.map((Queue methodQueue) => methodQueue.consume())))
    .then((Iterable<Consumer> consumers) {
      _rpcConsumers.addAll(consumers);

      // Bind a listener to each queue, passing the method that should be invoked
      consumers.forEach((Consumer consumer) {
        // Lookup the method that services this consumer
        RpcMethod rpcImplementation = _rpcNameToMethod[ consumer.queue.name ];

        // Bind listener
        consumer.listen((AmqpMessage message) {

          // Decode RPC args, pipe them to the RPC implementation, encode its response using the
          // supplied codec and send the reply back to the remote caller
          rpcCodec.decodeRpcRequest(rpcImplementation, message.payload)
          .then((List<Object> rpcArgs) {
            try {
              return rpcCodec.encodeRpcResponse(
                  rpcImplementation,
                  invokeRpcMethod(rpcImplementation, rpcArgs)
              );
            } catch (ex) {
              serverLogger.severe(ex);
              return rpcCodec.encodeError(ex);
            }
          })
          .then((Uint8List encodedResponse) => message.reply(encodedResponse))
          .catchError((ex) {
            serverLogger.severe(ex);
          });
        });
      });
      _connected.complete();
    });

    return _connected.future;
  }

  /**
   * This method is invoked by the RPC server in order to execute
   * [rpcMethod] using [rpcArgs] as arguments. A [Future] is
   * returned to be completed with the return value of the invoked method.
   *
   * This method is intentionally public so it may be overridden
   * by RPC server implementations that need to apply extra
   * logic before or after the method is executed
   */
  Future invokeRpcMethod(RpcMethod rpcMethod, List<Object> rpcArgs) {
    return rpcMethod.implementation.apply(rpcArgs).reflectee;
  }

  /**
   * Shutdown the RPC server and return a [Future] to be completed when
   * the server has shutdown.
   */
  Future close() {
    // Unbind all queues
    return Future.wait(_rpcConsumers.map((Consumer consumer) => consumer.cancel()))
    .then((_) {
      // shutdown the client only if we are using our own client
      return _usingExternalClient
      ? new Future.value()
      : _client.close();
    });
  }

}