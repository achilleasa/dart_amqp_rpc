///
//  Generated code. Do not modify.
///
library test;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';

class Invert extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('Invert')
    ..a(1, 'number', GeneratedMessage.QF)
  ;

  Invert() : super();
  Invert.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  Invert.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  Invert clone() => new Invert()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static Invert create() => new Invert();
  static PbList<Invert> createRepeated() => new PbList<Invert>();

  double get number => getField(1);
  void set number(double v) { setField(1, v); }
  bool hasNumber() => hasField(1);
  void clearNumber() => clearField(1);
}

class RpcError extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('RpcError')
    ..a(1, 'message', GeneratedMessage.QS)
  ;

  RpcError() : super();
  RpcError.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  RpcError.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  RpcError clone() => new RpcError()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static RpcError create() => new RpcError();
  static PbList<RpcError> createRepeated() => new PbList<RpcError>();

  String get message => getField(1);
  void set message(String v) { setField(1, v); }
  bool hasMessage() => hasField(1);
  void clearMessage() => clearField(1);
}

