import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../models/connected_device.dart';
import '../theme/app_theme.dart';

class DeviceConnectivityScreen extends StatefulWidget {
  const DeviceConnectivityScreen({super.key});

  @override
  State<DeviceConnectivityScreen> createState() =>
      _DeviceConnectivityScreenState();
}

class _DeviceConnectivityScreenState extends State<DeviceConnectivityScreen> {
  final List<ConnectedDevice> _devices = [
    ConnectedDevice(id: '1', name: 'Omron BP7000', type: DeviceType.bpMonitor),
    ConnectedDevice(
      id: '2',
      name: 'Accu-Chek Guide',
      type: DeviceType.glucoseMeter,
    ),
    ConnectedDevice(
      id: '3',
      name: 'iHealth Air',
      type: DeviceType.pulseOximeter,
    ),
  ];

  final Map<String, bool> _isConnecting = {};

  Future<void> _toggleConnection(ConnectedDevice device) async {
    if (device.isConnected) {
      setState(() {
        device.isConnected = false;
        device.lastReading = null;
        device.lastReadingTime = null;
      });
    } else {
      setState(() {
        _isConnecting[device.id] = true;
      });

      // Simulate connection delay
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isConnecting[device.id] = false;
          device.isConnected = true;
          device.batteryLevel = Random().nextInt(40) + 60; // 60-99%
          _simulateReading(device);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connected to ${device.name}')));
      }
    }
  }

  void _simulateReading(ConnectedDevice device) {
    setState(() {
      device.lastReadingTime = DateTime.now();

      switch (device.type) {
        case DeviceType.bpMonitor:
          final sys = 110 + Random().nextInt(30);
          final dia = 70 + Random().nextInt(20);
          device.lastReading = '$sys/$dia mmHg';
          break;
        case DeviceType.glucoseMeter:
          final glucose = 90 + Random().nextInt(30);
          device.lastReading = '$glucose mg/dL';
          break;
        case DeviceType.pulseOximeter:
          final spo2 = 95 + Random().nextInt(5);
          final hr = 60 + Random().nextInt(40);
          device.lastReading = 'SpO2: $spo2% | HR: $hr bpm';
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Connectivity')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          return _buildDeviceCard(_devices[index]);
        },
      ),
    );
  }

  Widget _buildDeviceCard(ConnectedDevice device) {
    final isConnecting = _isConnecting[device.id] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: device.isConnected
                        ? AppTheme.primaryBlue.withAlpha(26)
                        : Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withAlpha(10)
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getDeviceIcon(device.type),
                    color: device.isConnected
                        ? AppTheme.primaryBlue
                        : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.isConnected ? 'Connected' : 'Disconnected',
                        style: TextStyle(
                          color: device.isConnected
                              ? Colors.green
                              : Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isConnecting)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: device.isConnected,
                    onChanged: (value) => _toggleConnection(device),
                    activeTrackColor: AppTheme.primaryBlue,
                  ),
              ],
            ),
            if (device.isConnected) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Reading',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.lastReading ?? '--',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.battery_std,
                            size: 16,
                            color: _getBatteryColor(device.batteryLevel),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${device.batteryLevel}%',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          _simulateReading(device);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Syncing data...')),
                          );
                        },
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text('Sync Now'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.bpMonitor:
        return Icons.monitor_heart;
      case DeviceType.glucoseMeter:
        return Icons.water_drop;
      case DeviceType.pulseOximeter:
        return Icons.air;
    }
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }
}
