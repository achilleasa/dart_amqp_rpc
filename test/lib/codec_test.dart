library dart_amqp_rpc.test.codec;

import "dart:async";
import "dart:mirrors";
import "dart:typed_data";
import "dart:convert";

import "../../packages/unittest/unittest.dart";
import "../../lib/src/codec.dart";
import "../../lib/src/analyzer.dart";

import "proto/test.pb.dart" as proto;
import "logger/logger.dart";

class ProtobufCodec extends ProtobufRpcCodec {

  Future<Uint8List> encodeError(Object error) {
    proto.RpcError errorMessage = new proto.RpcError()
      ..message = error.toString();

    return new Future.value(errorMessage.writeToBuffer());
  }

  Future<Object> decodeError(Uint8List response) {
    return new Future.error(
        new proto.RpcError.fromBuffer(response)
    );
  }

}

main({bool enableLogger : true}) {
  if (enableLogger) {
    initLogger();
  }

  group("Codec test:", () {

    group("json", () {

      JsonRpcCodec codec;
      RpcMethod method;

      setUp(() {
        codec = new JsonRpcCodec();
        method = new RpcMethod()
          ..symbolName = new Symbol("foo")
          ..fqName = "rpc.foo"
          ..returnType = reflectClass(int)
          ..implementation = reflect((int value) {
          return value;
        })
          ..argList = [
          new RpcArgument("value", reflectClass(int))
        ];

      });

      test("encodeRpcRequest", () {
        dynamic encReq = codec.encodeRpcRequest(method, [ 200 ]);
        expect(encReq, new isInstanceOf<Future>());

        encReq
        .then(expectAsync((Uint8List payload) {
          List data = JSON.decode(new String.fromCharCodes(payload));
          expect(data, equals([200]));
        }));
      });

      test("decodeRpcRequest", () {
        dynamic encReq = codec.encodeRpcRequest(method, [ 200 ]);
        expect(encReq, new isInstanceOf<Future>());

        encReq
        .then((Uint8List payload) => codec.decodeRpcRequest(method, payload))
        .then(expectAsync((List<Object> args) {
          expect(args, equals([200]));
        }));
      });

      test("encodeRpcResponse", () {
        dynamic encRes = new Future.value(200);

        codec.encodeRpcResponse(method, encRes)
        .then(expectAsync((Uint8List payload) {
          dynamic data = JSON.decode(new String.fromCharCodes(payload));
          expect(data, new isInstanceOf<int>());
          expect(data, 200);
        }));
      });

      test("encodeRpcResponse with error", () {
        dynamic encRes = new Future.error(new ArgumentError("arg error"));

        codec.encodeRpcResponse(method, encRes)
        .then(expectAsync((Uint8List payload) {
          dynamic data = JSON.decode(new String.fromCharCodes(payload));
          expect(data, new isInstanceOf<Map>());
          expect(data, equals({"error" : "Invalid argument(s): arg error"}));
        }));
      });

      test("decodeRpcResponse", () {
        dynamic encRes = new Future.value(200);

        codec.encodeRpcResponse(method, encRes)
        .then((Uint8List payload) => codec.decodeRpcResponse(method, payload))
        .then(expectAsync((Object value) {
          expect(value, equals(200));
        }));
      });

      test("decodeRpcResponse with error", () {
        dynamic encRes = new Future.error(new ArgumentError("arg error"));

        codec.encodeRpcResponse(method, encRes)
        .then((Uint8List payload) => codec.decodeRpcResponse(method, payload))
        .catchError(expectAsync((e) {
          expect(e.toString(), contains("arg error"));
        }));
      });
    });

    group("protobuf", () {
      ProtobufCodec codec;
      RpcMethod method;
      proto.Invert testMessage;

      setUp(() {
        codec = new ProtobufCodec();
        method = new RpcMethod()
          ..symbolName = new Symbol("foo")
          ..fqName = "rpc.foo"
          ..returnType = reflectClass(proto.Invert)
          ..implementation = reflect((proto.Invert value) {
          value.number = 1.0 / value.number;
          return value;
        })
          ..argList = [
          new RpcArgument("value", reflectClass(proto.Invert))
        ];

        testMessage = new proto.Invert()
          ..number = 5.0;
      });

      test("encodeRpcRequest / decodeRpcRequest", () {
        dynamic encReq = codec.encodeRpcRequest(method, [ testMessage ]);
        expect(encReq, new isInstanceOf<Future>());

        encReq
        .then((Uint8List payload) => codec.decodeRpcRequest(method, payload))
        .then(expectAsync((List args) {
          expect(args.length, equals(1));
          proto.Invert message = args.first;
          expect(message.number, equals(5.0));
        }));
      });

      test("encodeRpcRequest with error", () {

        codec.encodeRpcRequest(method, [ testMessage ])
        .then((Uint8List payload) => codec.decodeRpcRequest(method, payload))
        .then(expectAsync((dynamic payload) {
          expect(payload, new isInstanceOf<List>());
          dynamic data = (payload as List).first;
          expect(data, new isInstanceOf<proto.Invert>());
          expect((data as proto.Invert).number, equals(5));
        }));
      });

      test("encodeRpcResponse / decodeRpcResponse", () {

        codec.encodeRpcResponse(method, new Future.value(testMessage))
        .then((Uint8List payload) => codec.decodeRpcResponse(method, payload))
        .then(expectAsync((dynamic data) {
          expect(data, new isInstanceOf<proto.Invert>());
          expect((data as proto.Invert).number, equals(5));
        }));
      });

      test("encodeRpcResponse / decodeRpcResponse with error", () {

        codec.encodeRpcResponse(method, new Future.error(new ArgumentError("invalid arg")))
        .then((Uint8List payload) => codec.decodeRpcResponse(method, payload))
        .catchError(expectAsync((dynamic data) {
          expect(data.toString(), contains("invalid arg"));
        }));
      });

      group("exceptions:", () {
        test("method not accepting a single protobuffer argument", () {

          method = new RpcMethod()
            ..symbolName = new Symbol("foo")
            ..fqName = "rpc.foo"
            ..returnType = reflectClass(proto.Invert)
            ..argList = [
            new RpcArgument("value", reflectClass(int))
          ];

          expect(
                  () => codec.validateRpcMethods([ method ]),
              throwsA((e) => e is Exception && e.toString().indexOf("should accept exactly one argument extending protobuf runtime-provided GeneratedMessage class") != -1)
          );
        });

        test("method not accepting > 1 protobuffer arguments", () {

          method = new RpcMethod()
            ..symbolName = new Symbol("foo")
            ..fqName = "rpc.foo"
            ..returnType = reflectClass(proto.Invert)
            ..argList = [
            new RpcArgument("value1", reflectClass(proto.Invert)),
            new RpcArgument("value2", reflectClass(proto.Invert))
          ];

          expect(
                  () => codec.validateRpcMethods([ method ]),
              throwsA((e) => e is Exception && e.toString().indexOf("should accept exactly one argument extending protobuf runtime-provided GeneratedMessage class") != -1)
          );
        });

        test("method not returning a protobuffer", () {

          method = new RpcMethod()
            ..symbolName = new Symbol("foo")
            ..fqName = "rpc.foo"
            ..returnType = reflectClass(int)
            ..argList = [
            new RpcArgument("value", reflectClass(proto.Invert))
          ];

          expect(
                  () => codec.validateRpcMethods([ method ]),
              throwsA((e) => e is Exception && e.toString().indexOf("should return a value extending protobuf runtime-provided GeneratedMessage class") != -1)
          );
        });

        test("error decoding request", () {
          Uint8List invalidData = new Uint8List.fromList([0xF0, 00]);
          codec.decodeRpcRequest(method, invalidData)
          .catchError(expectAsync((e) {
            expect(e.toString(), contains("InvalidProtocolBufferException"));
          }));
        });

        test("error decoding response", () {
          Uint8List invalidData = new Uint8List.fromList([0xF0, 00]);
          codec.decodeRpcResponse(method, invalidData)
          .catchError(expectAsync((e) {
            expect(e.toString(), contains("Unable to decode server response for RPC method"));
          }));
        });

        test("error decoding request", () {
          Uint8List invalidData = new Uint8List.fromList([0xF0, 00]);
          codec.decodeRpcRequest(method, invalidData)
          .catchError(expectAsync((e) {
            expect(e.toString(), contains("InvalidProtocolBufferException"));
          }));
        });

      });
    });
  });
}