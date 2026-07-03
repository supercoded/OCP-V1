import 'package:logging/logging.dart';

/// Returns a named logger for OCP components.
Logger ocpLogger(String name) => Logger('ocp.$name');
