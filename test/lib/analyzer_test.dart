library dart_amqp_rpc.test.analyzer;

import "dart:async";
import "dart:mirrors";

import "../../packages/unittest/unittest.dart";

import "../../lib/src/analyzer.dart";
import "logger/logger.dart";

class NonAbstractInterface {

}

abstract class AbstractInterfaceWithoutValidMethods {
  // Not returning a future; ignored by analyzer
  int foo(int bar);
}

abstract class ValidInterface {
  Future foo(int bar);

  Future<int> baz(int bar, NonAbstractInterface bam);
}

class ValidImpl implements ValidInterface {

  Future foo(int bar) {
    return new Future.value();
  }

  Future<int> baz(int bar, NonAbstractInterface bam) {
    return new Future.value(42);
  }
}

main({bool enableLogger : true}) {
  if (enableLogger) {
    initLogger();
  }

  group("Analyzer:", () {
    test("not abstract type exception", () {
      expect(() => Analyzer.analyzeInterface(NonAbstractInterface), throwsA((e) => e is ArgumentError && e.message == "Expected an abstract interface type; got NonAbstractInterface"));
    });

    test("no supported methods", () {
      List<RpcMethod> rpcMethods = Analyzer.analyzeInterface(AbstractInterfaceWithoutValidMethods);
      expect(rpcMethods.length, equals(0));
    });

    test("arg and return type analysis", () {
      List<RpcMethod> rpcMethods = Analyzer.analyzeInterface(ValidInterface, methodPrefix : "rpc");
      expect(rpcMethods.length, equals(2));

      // First method should have no return type (= dynamic) and a single argument of type int
      RpcMethod method = rpcMethods[0];
      expect(method.symbolName, equals(new Symbol("foo")));
      expect(method.fqName, equals("rpc.foo"));
      expect(method.implementation, isNull);
      expect(method.returnType, isNull);
      expect(method.argList.length, equals(1));
      RpcArgument arg = method.argList.first;
      expect(arg.name, equals("bar"));
      expect(arg.valueMirror, equals(reflectClass(int)));

      // Second method should have int as return type and 2 args of type int and NonAbstractInterface
      method = rpcMethods[1];
      expect(method.symbolName, equals(new Symbol("baz")));
      expect(method.fqName, equals("rpc.baz"));
      expect(method.implementation, isNull);
      expect(method.argList.length, equals(2));
      arg = method.argList.first;
      expect(arg.name, equals("bar"));
      expect(arg.valueMirror, equals(reflectClass(int)));
      arg = method.argList.last;
      expect(arg.name, equals("bam"));
      expect(arg.valueMirror, equals(reflectClass(NonAbstractInterface)));
    });

    test("method implementation analysis", () {
      List<RpcMethod> rpcMethods = Analyzer.analyzeInterface(ValidInterface, methodPrefix : "rpc", implementation : new ValidImpl());
      expect(rpcMethods.length, equals(2));

      // First method should have no return type (= dynamic) and a single argument of type int
      RpcMethod method = rpcMethods[0];
      expect(method.symbolName, equals(new Symbol("foo")));
      expect(method.fqName, equals("rpc.foo"));
      expect(method.implementation, new isInstanceOf<ClosureMirror>());
      expect(method.returnType, isNull);
      expect(method.argList.length, equals(1));
      RpcArgument arg = method.argList.first;
      expect(arg.name, equals("bar"));
      expect(arg.valueMirror, equals(reflectClass(int)));

      // Second method should have int as return type and 2 args of type int and NonAbstractInterface
      method = rpcMethods[1];
      expect(method.symbolName, equals(new Symbol("baz")));
      expect(method.fqName, equals("rpc.baz"));
      expect(method.implementation, new isInstanceOf<ClosureMirror>());
      expect(method.argList.length, equals(2));
      arg = method.argList.first;
      expect(arg.name, equals("bar"));
      expect(arg.valueMirror, equals(reflectClass(int)));
      arg = method.argList.last;
      expect(arg.name, equals("bam"));
      expect(arg.valueMirror, equals(reflectClass(NonAbstractInterface)));
    });
  });
}