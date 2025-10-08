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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[850]!.withOpacity(0.95),
                  Colors.grey[900]!.withOpacity(0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: meshService.isInitialized 
                    ? Colors.blue[400]!.withOpacity(0.6)
                    : Colors.grey[600]!.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(meshService),
                _buildStats(meshService),
                if (meshService.discoveredDevices.isNotEmpty)
                  Flexible(child: _buildDeviceList(meshService)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(MeshNetworkService meshService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: meshService.isInitialized 
              ? [Colors.blue[600]!, Colors.blue[800]!]
              : [Colors.grey[600]!, Colors.grey[800]!],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.device_hub, 
              color: Colors.white, 
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'MESH NETWORK',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          if (meshService.isInitialized)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'ONLINE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStats(MeshNetworkService meshService) {
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
        mainAxisSize: MainAxisSize.min,
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
          Flexible(
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
                  return _buildDeviceItem(device, meshService);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(
    NetworkDevice device,
    MeshNetworkService meshService,
  ) {
    final isConnected = device.isConnected;
    final signalQuality = device.signalQuality;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.deviceName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isConnected)
            SizedBox(
              width: 60,
              child: TextButton(
                onPressed: () => meshService.connectToDevice(device.deviceId),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Connect',
                  style: TextStyle(color: Colors.blue[300], fontSize: 11),
                ),
              ),
            )
          else
            SizedBox(
              width: 80,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Connected',
                    style: TextStyle(color: Colors.green, fontSize: 11),
                  ),
                ],
              ),
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
