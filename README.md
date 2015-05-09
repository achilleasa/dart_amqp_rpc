# dart_ampq_rpc

[![Build Status](https://drone.io/github.com/achilleasa/dart_amqp_rpc/status.png)](https://drone.io/github.com/achilleasa/dart_amqp_rpc/latest)
[![Coverage Status](https://coveralls.io/repos/achilleasa/dart_amqp_rpc/badge.svg)](https://coveralls.io/r/achilleasa/dart_amqp_rpc)

An opionated library for performing RPC over AMQP using JSON, protocol buffers
or custom user-defined codecs.

The library depends on AMQP functionality provided by the [dart_amqp](https://github.com/achilleasa/dart_amqp) package.

# Quick start

Define an interface to be used by the RPC client and server:

```dart
abstract class ArithInterface {
  Future<int> add(int a, int b);

  Future<double> div(int a, int b);
} 
```

Define your RPC server and implement the interface methods:

```dart
class ArithServer extends RpcServer implements ArithInterface {
  ArithServer() 
    : super.fromInterface(
        ArithInterface, 
        namespace : "org.example.arithserver" // Avoid name-clashes with synonymous 
                                              // methods using namespaces
    );

  Future<int> add(int a, int b) {
    return new Future.value( a + b );
  }

  Future<double> div(int a, int b) {
    // Passing b = 0 will cause a IntegerDivisionByZeroException
    return new Future.value(a / b);
  }
}
```

Define your RPC client:

```dart
class ArithClient extends RpcClient implements ArithInterface {
  ArithClient() 
    : super.fromInterface(
        ArithInterface, 
        namespace : "org.example.arithserver"
    );

  /**
   * Delegate any unknown [invocation] to [RpcClient].
   * Required to supress warnings that method does not implement the interface
   */
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

Use in your application (using JSON as the messaging codec):
```dart
void main(){
  // Both client and server will lazilly create an AMQP connection to localhost:5672
  // with the default guest credentials. See the API docs for details on using an
  // existing connection with the RPC server/client
  ArithServer server = new ArithServer();
  ArithClient client = new ArithClient();

  // Make sure server is connected before running tests 
  server.connect()
  .then((_){
    int pendingTests = 2;
    Completer completer = new Completer();

    // Test addition
    client
    .add(10, 5)
    .then((int res){
      print("10 + 5 = ${res}");
    })
    .whenComplete((){
      if( --pendingTests == 0 ){
        completer.complete();
      }
    });

    // Test error handling
    client
    .div(10, 0)
    .catchError((e){
      // Caught division by zero
      print("Caught: ${e}");
    })
    .whenComplete((){
      if( --pendingTests == 0 ){
        completer.complete();
      }
    });

    return completer.future;
  })
  .then((_) => Future.wait([client.close(), server.close()]));
}
```

# API


The library uses ```dart:mirrors``` to analyze the interface describing your service and detect any methods that
return ```Future```. These methods are further analyzed to collect information about their input and return argument types. The reasons for 
only considering methods returning a ```Future``` is that:
- RPC is asynchronous so the library would have to return a ```Future``` anyway.
- Since both client and server implement the same interface, you get support for local/remote interfaces which should also make testing much easier.
- It allows you to easily implement RPC servers with methods that in turn invoke one or more RPC services:

```dart
Future<List<int>> multiplex(){
	return Future.wait([
		client1.getData(),
		client2.getData()
	]);
}
```

## RPC method interface

Before writing your RPC server and client you need to first define your RPC method interface. This interface should be implemented by both the server and the client. When defining your interface keep in mind the following rules:

- Your RPC methods should return ```Future```; otherwise, they will be ignored.
- When using the protobuf codec, make sure you include the **type** on all arguments (input and output). The codec relies on this information to invoke the appropriate message constructors when processing incoming requests or responses.
- At this point, the library does not handling of named parameters to make it easier to interface with other languages that do not provide support for this feature. As a result, named parameters will be ignored when encoding/decoding RPC requests.

## RPC Server

The abstract [RpcServer](https://github.com/achilleasa/dart_amqp_rpc/blob/master/lib/src/rpc/rpc_server.dart) class handles all the heavy lifting
work:
- exposing each RPC method as an AMQP queue (with optional namespace support).
- listening for incoming requests.
- decoding requests via a messaging codec.
- invoking the appropriate method and handling its output or any thrown exception.
- package the response (or error) via the messaging codec and return it to the remote client.

Your RPC server implementation needs to extend [RpcServer](https://github.com/achilleasa/dart_amqp_rpc/blob/master/lib/src/rpc/rpc_server.dart) and implement your RPC method interface. Your class constructor
**must** invoke the [RpcServer](https://github.com/achilleasa/dart_amqp_rpc/blob/master/lib/src/rpc/rpc_server.dart).*fromInterface*
named constructor. This method receives your RPC method interface as its first argument the the following set of optional named
parameters:

|  Named parameter    | Description
|---------------------|-------------
| namespace           | A namespace value that is prepended to the method name in order to construct the AMQP queue name. If you have multiple RPC services exposing methods with the same name, you can use this parameter to prevent collisions. If not specified the default value **"rpc"** will be used.
| rpcCodec            | An [RpcCodec](https://github.com/achilleasa/dart_amqp_rpc/blob/master/lib/src/codec/rpc_codec.dart) instance to use for encoding/decoding RPC requests. If not specified, the default [JsonRpcCodec](#JSON) will be used.
| client              | An amqp client instance to use. If not specified, a client with the default values (localhost:5672, guest credentials) will be used instead.

To begin serving RPC connections, create a new instance of your RPC server class and invoke its ```connect()``` method.

## RPC Client

The [RpcClient](https://github.com/achilleasa/dart_amqp_rpc/blob/master/lib/src/rpc/rpc_client.dart) leverages ```noSuchMethod```
to provide a proxy for RPC methods. Whenever a known message is invoked, the RPC client:
- encodes the reqeust via a messaging codec
- sends it to the appropriate server queue (a v1 uuid is used as the message corellation-id to aid with demultiplexing of responses)
- receives the response, unpacks it with the messaging codec and returns the call value (or error) to the caller.

Your RPC client needs to extend [RpcClient](https://github.com/achilleasa/dart_amqp_rpc/blob/master/lib/src/rpc/rpc_client.dart) and implement your RPC method interface. Your class constructor
**must** invoke the [RpcClient](https://github.com/achilleasa/dart_amqp_rpc/blob/master/lib/src/rpc/rpc_client.dart).*fromInterface*
named constructor. This method receives your RPC method interface as its first argument the the following set of optional named
parameters:

|  Named parameter    | Description
|---------------------|-------------
| namespace           | A namespace value that is prepended to the method name in order to construct the AMQP queue name. If you have multiple RPC services exposing methods with the same name, you can use this parameter to prevent collisions. If not specified the default value **"rpc"** will be used.
| rpcCodec            | An [RpcCodec](https://github.com/achilleasa/dart_amqp_rpc/blob/master/lib/src/codec/rpc_codec.dart) instance to use for encoding/decoding RPC requests. If not specified, the default [JsonRpcCodec](#JSON) will be used.
| client              | An amqp client instance to use. If not specified, a client with the default values (localhost:5672, guest credentials) will be used instead.

To keep the Dart parser happy, you also need to define ```noSuchMethod``` in your client class that delegates to the [RpcClient](https://github.com/achilleasa/dart_amqp_rpc/blob/master/lib/src/rpc/rpc_client.dart) ```noSuchMethod``` implementation.

The RPC client will not establish an AMQP connection when you instanciate it but will automatically connect when you invoke any proxied RPC method. Alternatively, you may use the provided ```connect()``` method to establish a connection before invoking any RPC call.

## Codecs

### JSON

[JsonRpcCodec](https://github.com/achilleasa/dart_amqp_rpc/blob/master/lib/src/codec/impl/json_rpc_codec.dart) serves as the default messaging codec. It uses the JSON encoded from the ```dart:convert``` to encode RPC requests, responses and any caught error.

In order to use this codec your methods should receive and return arguments that can be serialized to JSON. 

### Protocol buffers

[ProtobufRpcCodec](https://github.com/achilleasa/dart_amqp_rpc/blob/master/lib/src/codec/impl/protobuf_rpc_codec.dart) uses the [dart-protobuf](https://pub.dartlang.org/packages/protobuf) runtime library to provide protocol buffer support. You can use the dart [protoc](https://github.com/dart-lang/dart-protoc-plugin) plugin to generate Dart classes from your protocol definition files.

This codec imposes additional constraints on the way you implement your RPC methods:
- they should receive exactly one protobuf message as their input.
- they should return a protobuf message.

In addition, the [ProtobufRpcCodec](https://github.com/achilleasa/dart_amqp_rpc/blob/master/lib/src/codec/impl/protobuf_rpc_codec.dart) is defined as **abstract** as it does not implement the required methods for encoding and decoding errors. Since protocol buffers do not define any special message for reporting errors you need to declare a message dedicated to error reporting and then define you own codec implementation
that provides the missing error encoding/decoding functions. 

For an example see the [codec](https://github.com/achilleasa/dart_amqp_rpc/blob/master/examples/fib_protobuf/lib/src/protobuf_codec.dart) implementation for the [fib_protobuf](https://github.com/achilleasa/dart_amqp_rpc/blob/master/examples/fib_protobuf) demo.

### User-defined codecs

If you need to use a different messaging codec you can always define your own by defining a class that implements [RpcCodec](https://github.com/achilleasa/dart_amqp_rpc/blob/master/lib/src/codec/rpc_codec.dart). To use you custom codec, you can instanciate it and
pass it to the RpcServer/RpcClient constructor via the ```rpcCodec``` named parameter.

# Examples

The [examples](https://github.com/achilleasa/dart_amqp_rpc/tree/master/examples) folder contains detailed examples on using this library to provide a fibonacci calculator service using **JSON** and **protocol buffers** as the messaging codecs.

# License

dart\_amqp\_rpc is distributed under the MIT license.
