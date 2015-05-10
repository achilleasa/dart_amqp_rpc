library dart_ampq_rpc.examples.protobuf;

import "dart:async";
import "dart:typed_data";
import "package:dart_amqp_rpc/dart_ampq_rpc.dart";
import "../../shared/utils.dart" as utils;

import "src/proto/fib.pb.dart";
export "src/proto/fib.pb.dart";

part "src/protobuf_codec.dart";
part "src/fib_interface.dart";
part "src/fib_client.dart";
part "src/fib_server.dart";
