/// Base OCP exception with structured error handling.
class OcpException implements Exception {
  const OcpException(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => 'OcpException($code): $message';
}
