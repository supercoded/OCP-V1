import 'package:isar/isar.dart';

/// Initializes Isar core for VM unit tests.
Future<void> initializeIsarForTests() =>
    Isar.initializeIsarCore(download: true);
