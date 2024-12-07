import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

/// Prints an error message to stderr.
void printError(String message) => stderr.writeln(message);

/// Prints a status message to stdout.
void printStatus(String message) => stdout.writeln(message);

/// Runs the [command] and returns its output as a string.
Future<String> runCommand(
  String command,
  List<String> args, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool expectNonZeroExit = false,
  int? expectedExitCode,
  String? failureMessage,
  Function? beforeExit,
}) async {
  final Process process = await startCommand(
    command,
    args,
    workingDirectory: workingDirectory,
    environment: environment,
  );

  final StringBuffer output = StringBuffer();
  final Completer<void> stdoutDone = Completer<void>();
  final Completer<void> stderrDone = Completer<void>();

  process.stdout.transform(utf8.decoder).listen((String str) {
    stdout.write(str);
    output.write(str);
  }, onDone: () {
    stdoutDone.complete();
  });

  process.stderr.transform(utf8.decoder).listen((String str) {
    stderr.write(str);
  }, onDone: () {
    stderrDone.complete();
  });

  await Future.wait<void>([stdoutDone.future, stderrDone.future]);

  final int exitCode = await process.exitCode;
  if ((exitCode != 0 && !expectNonZeroExit) || (expectedExitCode != null && exitCode != expectedExitCode)) {
    if (failureMessage != null) {
      printError(failureMessage);
    }
    if (beforeExit != null) {
      beforeExit();
    }
    exit(exitCode);
  }

  return output.toString().trim();
}

/// Starts the [command] and returns the [Process].
Future<Process> startCommand(
  String command,
  List<String> args, {
  String? workingDirectory,
  Map<String, String>? environment,
}) async {
  return await Process.start(
    command,
    args,
    workingDirectory: workingDirectory,
    environment: environment,
  );
}

/// Returns true if [version1] is considered greater than [version2].
@visibleForTesting
bool isVersionGreaterThan(String version1, String version2) {
  final List<int> version1Numbers = version1.split('.').map<int>((String value) => int.parse(value)).toList();
  final List<int> version2Numbers = version2.split('.').map<int>((String value) => int.parse(value)).toList();

  for (int i = 0; i < version1Numbers.length && i < version2Numbers.length; i++) {
    if (version1Numbers[i] > version2Numbers[i]) {
      return true;
    }
    if (version1Numbers[i] < version2Numbers[i]) {
      return false;
    }
  }
  return version1Numbers.length > version2Numbers.length;
}
