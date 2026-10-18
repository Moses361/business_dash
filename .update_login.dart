import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  var source = file.readAsStringSync();

  const importLine = "import 'auth/auth_gate.dart';";
  const flutterImport = "import 'package:flutter/material.dart';";

  if (!source.contains(importLine)) {
    if (!source.contains(flutterImport)) {
      stderr.writeln('Flutter import not found. No changes made.');
      exitCode = 1;
      return;
    }
    source = source.replaceFirst(
      flutterImport,
      '$flutterImport\n$importLine',
    );
  }

  const oldHome = 'home: const MainNavigation(),';
  const newHome = '''home: const AuthGate(
        signedInHome: MainNavigation(),
      ),''';

  if (source.contains(oldHome)) {
    source = source.replaceFirst(oldHome, newHome);
  } else if (!source.contains('home: const AuthGate(')) {
    stderr.writeln('Expected home line not found. No changes made.');
    exitCode = 1;
    return;
  }

  file.writeAsStringSync(source);
  stdout.writeln('Updated main.dart to use AuthGate.');
}
