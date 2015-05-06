library dart_amqp_rpc.test.codec;

import "dart:async";
import "dart:mirrors";
import "dart:typed_data";
import "dart:convert";

import "../../packages/unittest/unittest.dart";
import "../../lib/src/codec.dart";
import "../../lib/src/analyzer.dart";

import "proto/test.pb.dart" as pb;
import "proto/test.msgpack.dart" as mp;
import "logger/logger.dart";

class ProtobufCodec extends ProtobufRpcCodec {

  Future<Uint8List> encodeError(RpcMethod rpcMethod, List<Object> rpcArgs, Object error, {StackTrace trace}) {
    pb.RpcError errorMessage = new pb.RpcError()
      ..message = error.toString();

    return new Future.value(errorMessage.writeToBuffer());
  }

  Future<Object> decodeError(Uint8List response) {
    return new Future.error(
        new pb.RpcError.fromBuffer(response)
    );
  }

}

class MsgpackCodec extends MsgpackRpcCodec {

  Future<Uint8List> encodeError(RpcMethod rpcMethod, List<Object> rpcArgs, Object error, {StackTrace trace}) {
    mp.RpcError errorMessage = new mp.RpcError(error.toString());

    return new Future.value(new Uint8List.fromList(packer.packMessage(errorMessage)));
  }

  Future<Object> decodeError(Uint8List response) {
    return new Future.error(
        unpacker(response).unpackMessage(mp.RpcError.fromList)
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
          ..returnType = new RpcArgument("int", reflectClass(int))
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
        dynamic encRes = 200;

        codec.encodeRpcResponse(method, encRes)
        .then(expectAsync((Uint8List payload) {
          dynamic data = JSON.decode(new String.fromCharCodes(payload));
          expect(data, new isInstanceOf<int>());
          expect(data, 200);
        }));
      });

      test("decodeRpcResponse", () {
        dynamic encRes = 200;

        codec.encodeRpcResponse(method, encRes)
        .then((Uint8List payload) => codec.decodeRpcResponse(method, payload))
        .then(expectAsync((Object value) {
          expect(value, equals(200));
        }));
      });

      test("decodeRpcResponse with error", () {
        codec.encodeError(method, [], new ArgumentError("arg error"))
        .then((Uint8List payload) => codec.decodeRpcResponse(method, payload))
        .catchError(expectAsync((e) {
          expect(e.toString(), contains("arg error"));
        }));
      });
    });

    group("protobuf", () {
      ProtobufCodec codec;
      RpcMethod method;
      pb.Invert testMessage;

      setUp(() {
        codec = new ProtobufCodec();
        method = new RpcMethod()
          ..symbolName = new Symbol("foo")
          ..fqName = "rpc.foo"
          ..returnType = new RpcArgument("invert", reflectClass(pb.Invert))
          ..implementation = reflect((pb.Invert value) {
          value.number = 1.0 / value.number;
          return value;
        })
          ..argList = [
          new RpcArgument("value", reflectClass(pb.Invert))
        ];

        testMessage = new pb.Invert()
          ..number = 5.0;
      });

      test("encodeRpcRequest / decodeRpcRequest", () {
        dynamic encReq = codec.encodeRpcRequest(method, [ testMessage ]);
        expect(encReq, new isInstanceOf<Future>());

        encReq
        .then((Uint8List payload) => codec.decodeRpcRequest(method, payload))
        .then(expectAsync((List args) {
          expect(args.length, equals(1));
          pb.Invert message = args.first;
          expect(message.number, equals(5.0));
        }));
      });

      test("encodeRpcRequest with error", () {

        codec.encodeRpcRequest(method, [ testMessage ])
        .then((Uint8List payload) => codec.decodeRpcRequest(method, payload))
        .then(expectAsync((dynamic payload) {
          expect(payload, new isInstanceOf<List>());
          dynamic data = (payload as List).first;
          expect(data, new isInstanceOf<pb.Invert>());
          expect((data as pb.Invert).number, equals(5));
        }));
      });

      test("encodeRpcResponse / decodeRpcResponse", () {

        codec.encodeRpcResponse(method, testMessage)
        .then((Uint8List payload) => codec.decodeRpcResponse(method, payload))
        .then(expectAsync((dynamic data) {
          expect(data, new isInstanceOf<pb.Invert>());
          expect((data as pb.Invert).number, equals(5));
        }));
      });

      test("encodeRpcResponse / decodeRpcResponse with error", () {

        codec.encodeError(method, [], new ArgumentError("arg error"))
        .then((Uint8List payload) => codec.decodeRpcResponse(method, payload))
        .catchError(expectAsync((dynamic data) {
          expect(data.toString(), contains("arg error"));
        }));
      });

      group("exceptions:", () {
        test("method not accepting a single protobuffer argument", () {

          method = new RpcMethod()
            ..symbolName = new Symbol("foo")
            ..fqName = "rpc.foo"
            ..returnType = new RpcArgument("invert", reflectClass(pb.Invert))
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
            ..returnType = new RpcArgument("invert", reflectClass(pb.Invert))
            ..argList = [
            new RpcArgument("value1", reflectClass(pb.Invert)),
            new RpcArgument("value2", reflectClass(pb.Invert))
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
            ..returnType = new RpcArgument("int", reflectClass(int))
            ..argList = [
            new RpcArgument("value", reflectClass(pb.Invert))
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

    group("msgpack", () {
      MsgpackCodec codec;
      RpcMethod method;
      mp.Invert testMessage;

      setUp(() {
        codec = new MsgpackCodec();
        method = new RpcMethod()
          ..symbolName = new Symbol("foo")
          ..fqName = "rpc.foo"
          ..returnType = new RpcArgument("invert", reflectClass(mp.Invert))
          ..implementation = reflect((mp.Invert value) {
          value.flag = true;
          return value;
        })
          ..argList = [
          new RpcArgument("value", reflectClass(mp.Invert))
        ];

        testMessage = new mp.Invert(true);
      });

      test("encodeRpcRequest / decodeRpcRequest", () {
        dynamic encReq = codec.encodeRpcRequest(method, [ testMessage ]);
        expect(encReq, new isInstanceOf<Future>());

        encReq
        .then((Uint8List payload) => codec.decodeRpcRequest(method, payload))
        .then(expectAsync((List args) {
          expect(args.length, equals(1));
          mp.Invert message = args.first;
          expect(message.flag, equals(true));
        }));
      });

      test("encodeRpcRequest with error", () {

        codec.encodeRpcRequest(method, [ testMessage ])
        .then((Uint8List payload) => codec.decodeRpcRequest(method, payload))
        .then(expectAsync((dynamic payload) {
          expect(payload, new isInstanceOf<List>());
          dynamic data = (payload as List).first;
          expect(data, new isInstanceOf<mp.Invert>());
          expect((data as mp.Invert).flag, equals(true));
        }));
      });

      test("encodeRpcResponse / decodeRpcResponse", () {

        codec.encodeRpcResponse(method, testMessage)
        .then((Uint8List payload) => codec.decodeRpcResponse(method, payload))
        .then(expectAsync((dynamic data) {
          expect(data, new isInstanceOf<mp.Invert>());
          expect((data as mp.Invert).flag, equals(true));
        }));
      });

      group("exceptions:", () {
        test("method not accepting a single msgpack argument", () {

          method = new RpcMethod()
            ..symbolName = new Symbol("foo")
            ..fqName = "rpc.foo"
            ..returnType = new RpcArgument("invert", reflectClass(mp.Invert))
            ..argList = [
            new RpcArgument("value", reflectClass(int))
          ];

          expect(
                  () => codec.validateRpcMethods([ method ]),
              throwsA((e) => e is Exception && e.toString().indexOf("should accept exactly one argument extending msgpack runtime-provided Message class") != -1)
          );
        });

        test("method not accepting > 1 msgpack arguments", () {

          method = new RpcMethod()
            ..symbolName = new Symbol("foo")
            ..fqName = "rpc.foo"
            ..returnType = new RpcArgument("invert", reflectClass(mp.Invert))
            ..argList = [
            new RpcArgument("value1", reflectClass(mp.Invert)),
            new RpcArgument("value2", reflectClass(mp.Invert))
          ];

          expect(
                  () => codec.validateRpcMethods([ method ]),
              throwsA((e) => e is Exception && e.toString().indexOf("should accept exactly one argument extending msgpack runtime-provided Message class") != -1)
          );
        });

        test("method not returning a msgpack message", () {

          method = new RpcMethod()
            ..symbolName = new Symbol("foo")
            ..fqName = "rpc.foo"
            ..returnType = new RpcArgument("int", reflectClass(int))
            ..argList = [
            new RpcArgument("value", reflectClass(mp.Invert))
          ];

          expect(
                  () => codec.validateRpcMethods([ method ]),
              throwsA((e) => e is Exception && e.toString().indexOf("should return a value extending msgpack runtime-provided Message class") != -1)
          );
        });

        test("error decoding request", () {
          Uint8List invalidData = new Uint8List.fromList([0xF0, 00]);
          codec.decodeRpcRequest(method, invalidData)
          .catchError(expectAsync((e){}));
        });

        test("error decoding response", () {
          Uint8List invalidData = new Uint8List.fromList([0xF0, 00]);
          codec.decodeRpcResponse(method, invalidData)
          .catchError(expectAsync((e){}));
        });

        test("error decoding request", () {
          Uint8List invalidData = new Uint8List.fromList([0xF0, 00]);
          codec.decodeRpcRequest(method, invalidData)
          .catchError(expectAsync((e){}));
        });

      });
    });
  });
}