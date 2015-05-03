# dart\_ampq\_rpc : msgpack codec example

This example shows how to use ```dart_amqp_rpc``` using [msgpack](http://msgpack.org) as the RPC message exchange format.

The ```dart_amqp_rpc``` library internally uses the [msgpack](https://pub.dartlang.org/packages/msgpack) package to provide msgpack support.

## Running the example

The example contains a minimal command-line parser for tweaking the run parameters. To see the available options invoke the example with the ```-h``` argument:

```
dart --package-root=../../packages fib_msgpack.dart -h
```

```
Usage: dart --package-root=../../packages fib_msgpack.dart [-v] [--num-servers=X] [--from=X] [--to=X]

Where:
    -h              This help screen
    -v              Enable verbose output
    --num-servers   The number of RPC servers to spawn (default: 1)
    --from          The starting number for calculating fibonacci (default: 1)
    --to            The finishing number for calculating fibonnaci (default: 1)


Hint:
    To test the RPC error handling support, pass a negative number for calculating
    its fibonacci value. The example implementation is set up to throw an exception
    if it encounters a negative value.
```

The ```--num-servers``` option controls the number of spawned RPC servers. When multiple servers are available, RPC requests will be executed in parallel. You will also notice that responses will not arrive in order.

## The parts of the demo

[FibonacciInterface](https://github.com/achilleasa/dart_amqp_rpc/blob/master/examples/fib_msgpack/lib/src/fib_interface.dart) defines the RPC interface that is implemented by both [FibonnacciServer](https://github.com/achilleasa/dart_amqp_rpc/blob/master/examples/fib_msgpack/lib/src/fib_server.dart) and [FibonacciClient](https://github.com/achilleasa/dart_amqp_rpc/blob/master/examples/fib_msgpack/lib/src/fib_client.dart).

For this demo, I have defined 3 msgpack [messages](https://github.com/achilleasa/dart_amqp_rpc/blob/master/examples/fib_msgpack/lib/src/fib_message.dart) that are used for the RPC request, response and error reporting.

The msgpack [codec](https://github.com/achilleasa/dart_amqp_rpc/blob/master/examples/fib_msgpack/lib/src/msgpack_codec.dart) extends the library-provided abstract [MsgpackRpcCodec](https://github.com/achilleasa/dart_amqp_rpc/blob/master/lib/src/codec/impl/msgpack_rpc_codec.dart) and provides the required error-handling methods that wrap any caught error into our designated RPC error message (server-side) and unpack it accordingly on the client-side.

## Things to try

To calculate fibonacci for numbers 1 to 10 spread over 5 RPC servers:
```
dart --package-root=../../packages fib_msgpack.dart --num-servers=5 --from=1 --to=10
```

To see how errors are handled:

```
dart --package-root=../../packages fib_msgpack.dart --num-servers=1 --from=-1 --to=-1
```
