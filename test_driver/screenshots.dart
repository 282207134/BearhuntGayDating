import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  timeout: const Duration(minutes: 10),
  responseDataCallback: (data) async {
    final captures = data?['captures'] as Map<String, dynamic>?;
    if (captures == null || captures.length != 57) {
      throw StateError('Expected 57 captures, found ${captures?.length ?? 0}');
    }
    final target = Directory('docs/screenshots');
    await target.create(recursive: true);
    for (final entry in captures.entries) {
      await File(
        '${target.path}/${entry.key}.png',
      ).writeAsBytes(base64Decode(entry.value as String));
    }
  },
);
