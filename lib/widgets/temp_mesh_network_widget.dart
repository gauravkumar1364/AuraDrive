import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mesh_network_service.dart';
import '../models/models.dart';

class MeshNetworkWidget extends StatelessWidget {
  const MeshNetworkWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshNetworkService>(
      builder: (context, meshService, child) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Container(
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
                _buildHeader(meshService),
                _buildNetworkStats(meshService),
                if (meshService.discoveredDevices.isNotEmpty)
                  Expanded(child: _buildDeviceList(meshService)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(MeshNetworkService meshService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: meshService.isInitialized ? Colors.blue[700] : Colors.grey[700],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          Icon(Icons.device_hub, color: Colors.white, size: 20),
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
    );
  }

  Widget _buildNetworkStats(MeshNetworkService meshService) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
    );
  }

  Widget _buildDeviceList(MeshNetworkService meshService) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[700]!, width: 1)),
      ),
      child: Column(
        children: [
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
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: meshService.discoveredDevices.length,
                itemBuilder: (context, index) {
                  final device = meshService.discoveredDevices.values.elementAt(
                    index,
                  );
                  return _buildDeviceItem(context, device, meshService);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(
    BuildContext context,
    NetworkDevice device,
    MeshNetworkService meshService,
  ) {
    final isConnected = device.isConnected;
    final signalQuality = device.signalQuality;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.smartphone, color: Colors.white, size: 20),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                Text(
                  device.deviceId,
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.signal_cellular_alt,
                    color: _getSignalColor(signalQuality),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${signalQuality}%',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isConnected ? 'Connected' : 'Available',
                style: TextStyle(
                  color: isConnected ? Colors.green : Colors.grey[400],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
      ],
    );
  }

  Color _getSignalColor(int quality) {
    if (quality >= 80) return Colors.green;
    if (quality >= 60) return Colors.orange;
    if (quality >= 40) return Colors.yellow;
    return Colors.red;
  }
}
