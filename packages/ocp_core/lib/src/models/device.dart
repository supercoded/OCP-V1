/// Device domain model.
class Device {
  const Device({
    required this.deviceId,
    required this.workspaceId,
    required this.name,
    this.transportType,
    required this.capabilities,
    this.firmwareVersion,
    required this.isPaired,
    this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String deviceId;
  final String workspaceId;
  final String name;
  final String? transportType;
  final List<String> capabilities;
  final String? firmwareVersion;
  final bool isPaired;
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
