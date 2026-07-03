import 'dart:convert';
import 'dart:io';

import 'package:mock_device/mock_device.dart';

void main() async {
  final device = MockOdpDevice();
  stdout.writeln('mock_device ready');
  await for (final line in stdin.transform(utf8.decoder)) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final bytes = base64Decode(trimmed);
    final response = device.handle(bytes);
    if (response != null) {
      stdout.writeln(base64Encode(response));
    }
  }
}
