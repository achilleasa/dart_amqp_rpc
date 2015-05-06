library dart_amqp_rpc.test.rpc;

import "dart:async";

import "../../packages/unittest/unittest.dart";
import "../../packages/dart_amqp_rpc/dart_ampq_rpc.dart";
import "package:dart_amqp/dart_amqp.dart" as amqp;

import "logger/logger.dart";

abstract class IncompatibleInterface {
  // This method does not return a Future so it will not
  // be considered as a valid RPC proxy
  String echo(String value);
}

abstract class TestRpcInterface {
  Future<double> invert(double value);

  Future<bool> methodThatFails();
}

class IncompatibleTestClient extends RpcClient implements TestRpcInterface {

  IncompatibleTestClient(String namespace, [amqp.Client client = null]) : super.fromInterface(IncompatibleInterface, namespace : namespace, client : client);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


class TestClient extends RpcClient implements TestRpcInterface {

  TestClient(String namespace, [amqp.Client client = null]) : super.fromInterface(TestRpcInterface, namespace : namespace, client : client);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestServer extends RpcServer implements TestRpcInterface {

  TestServer(String namespace, [amqp.Client client = null]) : super.fromInterface(TestRpcInterface, namespace : namespace, client : client);

  Future<double> invert(double value) {
    if (value == 0) {
      throw new ArgumentError("Cannot calculate inverted value for input = 0");
    }

    return new Future.value(1.0 / value);
  }

  Future<bool> methodThatFails() {
    return new Future.error(new UnimplementedError("Not implemented"));
  }
}

class IncompatibleTestServer extends RpcServer {
  IncompatibleTestServer(String namespace, [amqp.Client client = null]) : super.fromInterface(IncompatibleInterface, namespace : namespace, client : client);
}

main({bool enableLogger : true}) {
  if (enableLogger) {
    initLogger();
  }

  group("Rpc test:", () {

    group("client", () {
      group("exceptions:", () {
        test("no RPC methods", () {
          expect(() => new IncompatibleTestClient(""), throwsA((e) => e is ArgumentError && e.message == "No RPC methods defined/implemented. Ensure that your RPC interface defines at least one method returning Future and that your RPC server implements it."));
        });

        test("invoking non-proxied method", () {
          TestClient rpcClient = new TestClient("");

          expect( () => rpcClient.foo(), throwsNoSuchMethodError);
        });

      });


      test("multiple connect attempts", () {
        TestClient rpcClient = new TestClient("");

        return rpcClient.connect()
        .then((_) => rpcClient.connect())
        .then((_) => rpcClient.connect())
        .then((_) => rpcClient.close());
      });

      group("configuration options", () {

        test("null method prefix", () {
          TestClient rpcClient = new TestClient(null);

          expect(rpcClient.namespace, equals("rpc"));
          return rpcClient
          .connect()
          .then((_) => rpcClient.close());
        });

        test("empty method prefix", () {
          TestClient rpcClient = new TestClient("");

          expect(rpcClient.namespace, equals("rpc"));
        });

        test("when using external client, client should remain open after rpc client closes", () {
          amqp.Client extClient = new amqp.Client();
          amqp.Channel extChannel;
          TestClient rpcClient;

          return extClient.channel()
          .then((amqp.Channel ch) {
            extChannel = ch;

            rpcClient = new TestClient("test", extClient);
            expect(rpcClient.namespace, equals("test"));

            // Connect rpc client
            return rpcClient.connect();
          })
          .then((_) => rpcClient.close())
          .then((_) => extChannel.close())
          .then((_) => extClient.close());
        });
      });

    });

    group("server", () {
      test("no RPC methods exception", () {
        expect(() => new IncompatibleTestServer(""), throwsA((e) => e is ArgumentError && e.message == "No RPC methods defined/implemented. Ensure that your RPC interface defines at least one method returning Future and that your RPC server implements it."));
      });

      test("multiple connect attempts", () {
        TestServer rpcServer = new TestServer("");

        return rpcServer.connect()
        .then((_) => rpcServer.connect())
        .then((_) => rpcServer.connect())
        .then((_) => rpcServer.close());
      });

      group("configuration options", () {
        test("null method prefix", () {
          TestServer rpcServer = new TestServer(null);

          expect(rpcServer.namespace, equals("rpc"));
          return rpcServer
          .connect()
          .then((_) => rpcServer.close());
        });

        test("empty method prefix", () {
          TestServer rpcServer = new TestServer("");

          expect(rpcServer.namespace, equals("rpc"));
        });

        test("when using external client, client should remain open after rpc server closes", () {
          amqp.Client extClient = new amqp.Client();
          amqp.Channel extChannel;
          TestServer rpcServer;

          return extClient.channel()
          .then((amqp.Channel ch) {
            extChannel = ch;

            rpcServer = new TestServer("test", extClient);
            expect(rpcServer.namespace, equals("test"));

            // Connect rpc client
            return rpcServer.connect();
          })
          .then((_) => rpcServer.close())
          .then((_) => extChannel.close())
          .then((_) => extClient.close());
        });
      });
    });

    group("rpc calls", () {
      TestClient rpcClient;
      TestServer rpcServer;

      setUp(() {
        rpcServer = new TestServer("rpc");
        rpcClient = new TestClient("rpc");

        return Future.wait([
          rpcServer.connect(),
          rpcClient.connect()
        ]);
      });

      tearDown(() {
        return rpcServer
        .close()
        .then((_) => rpcClient.close());
      });

      test("simple call", () {
        rpcClient.invert(5.0)
        .then(expectAsync((double val) {
          expect(val, equals(1.0 / 5.0));
        }));
      });

      test("exception handling (method throws)", () {
        rpcClient.invert(0.0)
        .catchError(expectAsync((e) {
          expect(e.toString(), equals("Invalid argument(s): Cannot calculate inverted value for input = 0"));
        }));
      });

      test("exception handling (method returns failed Future)", () {
        rpcClient.methodThatFails()
        .catchError(expectAsync((e) {
          expect(e.toString(), equals("UnimplementedError: Not implemented"));
        }));
      });
    });
  });
}