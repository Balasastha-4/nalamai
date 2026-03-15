enum DeviceType { bpMonitor, glucoseMeter, pulseOximeter }

class ConnectedDevice {
  final String id;
  final String name;
  final DeviceType type;
  bool isConnected;
  int batteryLevel;
  String? lastReading;
  DateTime? lastReadingTime;

  ConnectedDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isConnected = false,
    this.batteryLevel = 100,
    this.lastReading,
    this.lastReadingTime,
  });
}
