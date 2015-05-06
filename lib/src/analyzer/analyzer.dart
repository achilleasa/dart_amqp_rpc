part of dart_amqp_rpc.analyzer;


class Analyzer {
  /**
   * Detect the RPC candidate methods defined by [rpcInterface] that are
   * optionally implemented by [implementation]. RPC candidates are methods
   * that return back a [Future].
   *
   * An optional [namespace] may be specified to build the fully qualified
   * rpc endpoint name so as to avoid name clashes between similarly named
   * methods by different interfaces.
   *
   * This method returns a [List<RpcMethod>] with the discovered methods or
   * throws an [ArgumentError] if reflection on [rpcInterface] fails.
   */
  static List<RpcMethod> analyzeInterface(Type rpcInterface, { String namespace, Object implementation}) {

    List<RpcMethod> methodList = [];
    Symbol dynamic = new Symbol("dynamic");

    // Lookup rpc interface
    ClassMirror interfaceMirror = reflectType(rpcInterface);
    if (interfaceMirror == null || !interfaceMirror.isAbstract) {
      throw new ArgumentError("Expected an abstract interface type; got ${rpcInterface}");
    }

    // Lookup implementation instance details
    InstanceMirror implMirror = implementation != null
    ? reflect(implementation)
    : null;

    // Analyze declarations and process methods returning Futures
    interfaceMirror.declarations.forEach((Symbol declName, DeclarationMirror dm) {
      if (dm is! MethodMirror || dm.isPrivate) {
        return;
      }

      MethodMirror methodMirror = dm as MethodMirror;
      if (!methodMirror.isAbstract || MirrorSystem.getName(methodMirror.returnType.simpleName) != "Future") {
        return;
      }

      // Ignore methods not implemented by implMirror
      ClosureMirror methodImplMirror = null;
      if (implMirror != null) {
        methodImplMirror = implMirror.getField(declName);

        // Interface method not implemented by supplied instance
        if (methodImplMirror == null) {
          return;
        }
      }

      RpcMethod method = new RpcMethod()
        ..symbolName = declName
        ..fqName = "${namespace}.${MirrorSystem.getName(declName)}"
        ..implementation = methodImplMirror
        ..argList = methodMirror.parameters.map(
              (ParameterMirror pm) => new RpcArgument(
              MirrorSystem.getName(pm.simpleName),
              reflectClass(pm.type.reflectedType)
          )).toList(growable : false);

      // Analyze the method return type generics metadata
      // and try to identify the real return type after the
      // future is evaluated
      if (!methodMirror.returnType.typeArguments.isEmpty) {
        TypeMirror returnTypeMirror = methodMirror.returnType.typeArguments[0];
        method.returnType = returnTypeMirror.simpleName == dynamic
          ? null
          : new RpcArgument(MirrorSystem.getName(returnTypeMirror.simpleName), returnTypeMirror);
      }

      methodList.add(method);
    });

    return methodList;
  }
}