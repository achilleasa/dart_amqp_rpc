library dart_ampq_rpc.examples.utils;

/**
 * Recursive implementation of fibonacci calculator
 * for value [n]
 */
int fibRecursive(int n) {
  if (n < 0 ){
    throw new ArgumentError("Expected a number >= 0; ${n} given");
  } else if (n == 0) {
    return 0;
  } else if (n == 1) {
    return 1;
  }
  return fibRecursive(n - 1) + fibRecursive(n - 2);
}

/**
 * Iterative implementation of fibonacci calculator
 * for value [n]
 */
int fibIterative(int n) {
  if (n < 0 ){
    throw new ArgumentError("Expected a number >= 0; ${n} given");
  } else if (n == 0) {
    return 0;
  } else if (n == 1 || n == 2) {
    return 1;
  }

  int pp = 1;
  int prev = 1;
  int res = 0;
  for (int i = 1; i <= n - 2; i++) {
    res = prev + pp;
    pp = prev;
    prev = res;
  }
  return res;
}