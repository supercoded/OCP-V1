/// A recently-used connection entry for quick reconnect from the Devices page.
class RecentConnection {
  final String host;
  final int port;
  final String transportKind; // 'TCP', 'Serial', 'BLE', 'Auto'
  final DateTime lastUsed;

  const RecentConnection({
    required this.host,
    required this.port,
    required this.transportKind,
    required this.lastUsed,
  });

  Map<String, dynamic> toMap() => {
        'host': host,
        'port': port,
        'transportKind': transportKind,
        'lastUsed': lastUsed.millisecondsSinceEpoch,
      };

  factory RecentConnection.fromMap(Map<String, dynamic> map) =>
      RecentConnection(
        host: map['host'] as String? ?? '',
        port: (map['port'] as num?)?.toInt() ?? 0,
        transportKind: map['transportKind'] as String? ?? 'TCP',
        lastUsed: map['lastUsed'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['lastUsed'] as int)
            : DateTime.now(),
      );

  RecentConnection copyWith({
    String? host,
    int? port,
    String? transportKind,
    DateTime? lastUsed,
  }) =>
      RecentConnection(
        host: host ?? this.host,
        port: port ?? this.port,
        transportKind: transportKind ?? this.transportKind,
        lastUsed: lastUsed ?? this.lastUsed,
      );

  /// A unique key to deduplicate connections with the same host+port+transport.
  String get key => '$host:$port:$transportKind';

  @override
  String toString() => '$transportKind://$host:$port';
}