///
//  Generated code. Do not modify.
///
library fib;

import 'package:protobuf/protobuf.dart';

class FibQuery extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('FibQuery')
    ..a(1, 'number', GeneratedMessage.Q3)
    ..a(2, 'useRecursion', GeneratedMessage.OB)
  ;

  FibQuery() : super();
  FibQuery.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  FibQuery.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  FibQuery clone() => new FibQuery()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static FibQuery create() => new FibQuery();
  static PbList<FibQuery> createRepeated() => new PbList<FibQuery>();

  int get number => getField(1);
  void set number(int v) { setField(1, v); }
  bool hasNumber() => hasField(1);
  void clearNumber() => clearField(1);

  bool get useRecursion => getField(2);
  void set useRecursion(bool v) { setField(2, v); }
  bool hasUseRecursion() => hasField(2);
  void clearUseRecursion() => clearField(2);
}

class FibValue extends GeneratedMessage {
  static final BuilderInfo _i = new BuilderInfo('FibValue')
    ..a(1, 'number', GeneratedMessage.Q3)
  ;

  FibValue() : super();
  FibValue.fromBuffer(List<int> i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  FibValue.fromJson(String i, [ExtensionRegistry r = ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  FibValue clone() => new FibValue()..mergeFromMessage(this);
  BuilderInfo get info_ => _i;
  static FibValue create() => new FibValue();
  static PbList<FibValue> createRepeated() => new PbList<FibValue>();

  int get number => getField(1);
  void set number(int v) { setField(1, v); }
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

