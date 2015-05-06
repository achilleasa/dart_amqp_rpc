# dart\_ampq\_rpc : JSON codec example

This example shows how to use ```dart_amqp_rpc``` using JSON as the RPC message exchange format. The library uses
the JSON codec by default if no codec is specified when instanciating the client or the server.

## Running the example

The example contains a minimal command-line parser for tweaking the run parameters. To see the available options invoke the example with the ```-h``` argument:

```
dart --package-root=../../packages fib_json.dart -h
```

```
Usage: dart --package-root=../../packages fib_json.dart [-v] [--num-servers=X] [--from=X] [--to=X]

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

[FibonacciInterface](https://github.com/achilleasa/dart_amqp_rpc/blob/master/examples/fib_json/lib/src/fib_interface.dart) defines the RPC interface that is implemented by both [FibonnacciServer](https://github.com/achilleasa/dart_amqp_rpc/blob/master/examples/fib_json/lib/src/fib_server.dart) and [FibonacciClient](https://github.com/achilleasa/dart_amqp_rpc/blob/master/examples/fib_json/lib/src/fib_client.dart).

The codec will transparently serialize/unserialize any RPC method arguments to/from JSON as long
as they can be encoded/decoded by the built-in ```dart:convert``` package.

## Things to try

To calculate fibonacci for numbers 1 to 10 spread over 5 RPC servers:
```
dart --package-root=../../packages fib_json.dart --num-servers=5 --from=1 --to=10
```

To see how errors are handled:

```
dart --package-root=../../packages fib_json.dart --num-servers=1 --from=-1 --to=-1
```
