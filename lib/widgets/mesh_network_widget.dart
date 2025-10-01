import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mesh_network_service.dart';
import '../models/models.dart';

/// Widget for displaying mesh network status and controls
class MeshNetworkWidget extends StatelessWidget {
  const MeshNetworkWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshNetworkService>(
      builder: (context, meshService, child) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: meshService.isInitialized ? Colors.blue : Colors.grey,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: meshService.isInitialized ? Colors.blue[700] : Colors.grey[700],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.device_hub,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MESH NETWORK',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Network statistics
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Status row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          'Status',
                          meshService.isInitialized ? 'Online' : 'Offline',
                          meshService.isInitialized ? Colors.green : Colors.red,
                        ),
                        _buildStatItem(
                          'Connected',
                          '${meshService.connectedDeviceCount}',
                          Colors.blue,
                        ),
                        _buildStatItem(
                          'Discovered',
                          '${meshService.discoveredDevices.length}',
                          Colors.orange,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Controls
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: meshService.isInitialized
                                ? (meshService.isScanning
                                    ? () => meshService.stopScanning()
                                    : () => meshService.startScanning())
                                : null,
                            icon: Icon(
                              meshService.isScanning ? Icons.stop : Icons.search,
                              size: 16,
                            ),
                            label: Text(
                              meshService.isScanning ? 'Stop Scan' : 'Scan',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Device list
              if (meshService.discoveredDevices.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              'Nearby Devices',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${meshService.discoveredDevices.length} found',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Device list
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: meshService.discoveredDevices.length,
                          itemBuilder: (context, index) {
                            final device = meshService.discoveredDevices.values.elementAt(index);
                            return _buildDeviceItem(context, device, meshService);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Network statistics details
              if (meshService.isInitialized)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: _buildNetworkStats(meshService),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Build device item
  Widget _buildDeviceItem(BuildContext context, NetworkDevice device, MeshNetworkService meshService) {
    final isConnected = device.isConnected;
    final signalQuality = device.signalQuality;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[800]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Device icon and status
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getDeviceStatusColor(device.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          
          // Device info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.deviceName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.signal_cellular_alt,
                      color: _getSignalColor(signalQuality),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$signalQuality%',
                      style: TextStyle(
                        color: _getSignalColor(signalQuality),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (device.estimatedDistance != null) ...[
                      Icon(
                        Icons.social_distance,
                        color: Colors.grey[400],
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${device.estimatedDistance!.toStringAsFixed(0)}m',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Connect button
          if (!isConnected)
            TextButton(
              onPressed: () => meshService.connectToDevice(device.deviceId),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
              child: Text(
                'Connect',
                style: TextStyle(
                  color: Colors.blue[300],
                  fontSize: 11,
                ),
              ),
            )
          else
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 16,
            ),
        ],
      ),
    );
  }

  /// Build network statistics
  Widget _buildNetworkStats(MeshNetworkService meshService) {
    final stats = meshService.getNetworkStatistics();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Network Statistics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatDetail('Data Transfer', stats['dataTransferActive'] ? 'Active' : 'Idle'),
            _buildStatDetail('Health', stats['networkHealth']),
            _buildStatDetail('Signal Avg', '${stats['averageSignalStrength']}%'),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Cooperative positioning devices
        if (meshService.cooperativePositioningDevices.isNotEmpty)
          Text(
            'Cooperative Positioning: ${meshService.cooperativePositioningDevices.length} suitable devices',
            style: TextStyle(
              color: Colors.green[300],
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  /// Build statistics item
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// Build statistics detail
  Widget _buildStatDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  /// Get color for device status
  Color _getDeviceStatusColor(NetworkDeviceStatus status) {
    return switch (status) {
      NetworkDeviceStatus.connected => Colors.green,
      NetworkDeviceStatus.connecting => Colors.orange,
      NetworkDeviceStatus.disconnecting => Colors.orange,
      NetworkDeviceStatus.offline => Colors.grey,
      NetworkDeviceStatus.error => Colors.red,
    };
  }

  /// Get color for signal strength
  Color _getSignalColor(int signalQuality) {
    if (signalQuality >= 75) return Colors.green;
    if (signalQuality >= 50) return Colors.orange;
    if (signalQuality >= 25) return Colors.red;
    return Colors.grey;
  }
}