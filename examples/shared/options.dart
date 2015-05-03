library dart_ampq_rpc.examples.options;

import "dart:io";

class Options {

  // The number of RPC servers to use
  int numServers = 1;

  // The starting and finishing number for calculating fibonacci values
  int from = 1;
  int to = 1;

  // Enable verbose logging
  bool verbose = false;

  Options._();
}

void _showHelp(String scriptName) {
  print("""
Usage: dart --package-root=../../packages ${scriptName} [-v] [--num-servers=X] [--from=X] [--to=X]

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

""");
}

// Parse command line args
Options parse(String scriptName, List<String> args) {
  Options options = new Options._();

  args.forEach((String arg) {

    if (arg == "-v") {
      options.verbose = true;
      return;
    }

    // Check for key=value options
    if (arg.indexOf("=") == -1) {
      _showHelp(scriptName);
      exit(1);
    }

    List<String> tokens = arg.split("=");
    switch (tokens[0]) {
      case "--num-servers":
        options.numServers = int.parse(tokens[1]);
        break;
      case "--from":
        options.from = int.parse(tokens[1]);
        break;
      case "--to":
        options.to = int.parse(tokens[1]);
        break;
    }
  });

  return options;
}