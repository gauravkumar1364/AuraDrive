import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE Diagnostic utility to check Bluetooth status and capabilities
class BLEDiagnostic {
  /// Run comprehensive BLE diagnostic tests
  static Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{};
    
    print('=== BLE Diagnostic Test Started ===');
    
    // Test 1: Check if BLE is supported
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      results['ble_supported'] = isSupported;
      print('✓ BLE Supported: $isSupported');
    } catch (e) {
      results['ble_supported'] = false;
      results['support_error'] = e.toString();
      print('✗ Error checking BLE support: $e');
    }
    
    // Test 2: Check adapter state
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      results['adapter_state'] = adapterState.toString();
      results['bluetooth_on'] = adapterState == BluetoothAdapterState.on;
      print('✓ Adapter State: $adapterState');
      print('✓ Bluetooth Enabled: ${adapterState == BluetoothAdapterState.on}');
    } catch (e) {
      results['adapter_error'] = e.toString();
      print('✗ Error checking adapter state: $e');
    }
    
    // Test 3: Check if scanning is possible
    try {
      final isScanning = FlutterBluePlus.isScanningNow;
      results['currently_scanning'] = isScanning;
      print('✓ Currently Scanning: $isScanning');
    } catch (e) {
      results['scanning_check_error'] = e.toString();
      print('✗ Error checking scan status: $e');
    }
    
    // Test 4: Attempt a quick scan
    if (results['bluetooth_on'] == true) {
      try {
        print('▶ Attempting test scan...');
        final scanResults = <ScanResult>[];
        
        // Listen to scan results
        final subscription = FlutterBluePlus.scanResults.listen((results) {
          scanResults.addAll(results);
        });
        
        // Start scan
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 5),
          androidUsesFineLocation: true,
        );
        
        // Wait for scan to complete
        await Future.delayed(const Duration(seconds: 6));
        
        // Stop scan
        await FlutterBluePlus.stopScan();
        subscription.cancel();
        
        results['test_scan_success'] = true;
        results['devices_found'] = scanResults.length;
        results['device_details'] = scanResults.map((r) => {
          'id': r.device.remoteId.toString(),
          'name': r.device.platformName,
          'rssi': r.rssi,
        }).toList();
        
        print('✓ Test scan completed successfully');
        print('✓ Devices found: ${scanResults.length}');
        
        for (final result in scanResults) {
          print('  - Device: ${result.device.platformName.isEmpty ? "Unknown" : result.device.platformName} (${result.device.remoteId}) RSSI: ${result.rssi}');
        }
        
      } catch (e) {
        results['test_scan_success'] = false;
        results['scan_error'] = e.toString();
        print('✗ Test scan failed: $e');
      }
    } else {
      results['test_scan_success'] = false;
      results['scan_error'] = 'Bluetooth not enabled';
      print('⚠ Skipping test scan - Bluetooth not enabled');
    }
    
    // Test 5: Platform information
    results['platform_info'] = {
      'flutter_blue_plus_version': '1.32.12',
    };
    
    print('=== BLE Diagnostic Test Completed ===');
    print('Summary:');
    print('  - BLE Supported: ${results['ble_supported']}');
    print('  - Bluetooth On: ${results['bluetooth_on']}');
    print('  - Test Scan: ${results['test_scan_success']}');
    print('  - Devices Found: ${results['devices_found'] ?? 0}');
    
    return results;
  }
  
  /// Get human-readable diagnostic report
  static String getDiagnosticReport(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('=== BLE DIAGNOSTIC REPORT ===\n');
    
    // BLE Support
    buffer.writeln('1. BLE Support');
    if (results['ble_supported'] == true) {
      buffer.writeln('   ✓ BLE is supported on this device');
    } else {
      buffer.writeln('   ✗ BLE is NOT supported on this device');
      if (results['support_error'] != null) {
        buffer.writeln('   Error: ${results['support_error']}');
      }
    }
    buffer.writeln();
    
    // Adapter State
    buffer.writeln('2. Bluetooth Adapter');
    if (results['bluetooth_on'] == true) {
      buffer.writeln('   ✓ Bluetooth is enabled');
      buffer.writeln('   State: ${results['adapter_state']}');
    } else {
      buffer.writeln('   ✗ Bluetooth is NOT enabled');
      buffer.writeln('   State: ${results['adapter_state']}');
      buffer.writeln('   ACTION REQUIRED: Please enable Bluetooth');
    }
    buffer.writeln();
    
    // Scanning Capability
    buffer.writeln('3. Scanning Test');
    if (results['test_scan_success'] == true) {
      buffer.writeln('   ✓ Scanning works correctly');
      buffer.writeln('   Devices found: ${results['devices_found']}');
      
      if (results['devices_found'] > 0) {
        buffer.writeln('\n   Discovered Devices:');
        final devices = results['device_details'] as List?;
        if (devices != null) {
          for (var i = 0; i < devices.length; i++) {
            final device = devices[i] as Map;
            buffer.writeln('   ${i + 1}. ${device['name'].isEmpty ? "Unknown Device" : device['name']}');
            buffer.writeln('      ID: ${device['id']}');
            buffer.writeln('      RSSI: ${device['rssi']} dBm');
          }
        }
      } else {
        buffer.writeln('   ℹ No devices found during scan');
        buffer.writeln('   Note: Make sure other BLE devices are nearby and advertising');
      }
    } else {
      buffer.writeln('   ✗ Scanning failed');
      if (results['scan_error'] != null) {
        buffer.writeln('   Error: ${results['scan_error']}');
      }
    }
    buffer.writeln();
    
    // Recommendations
    buffer.writeln('4. Recommendations');
    if (results['ble_supported'] != true) {
      buffer.writeln('   • Your device does not support BLE');
    } else if (results['bluetooth_on'] != true) {
      buffer.writeln('   • Enable Bluetooth in device settings');
      buffer.writeln('   • Make sure Location services are enabled (required for BLE on Android)');
    } else if (results['test_scan_success'] != true) {
      buffer.writeln('   • Check app permissions for Bluetooth and Location');
      buffer.writeln('   • Restart the app after granting permissions');
      buffer.writeln('   • Make sure Location services are enabled');
    } else if (results['devices_found'] == 0) {
      buffer.writeln('   • BLE is working correctly');
      buffer.writeln('   • No devices found - this is normal if no BLE devices are nearby');
      buffer.writeln('   • Try with known BLE devices (fitness trackers, headphones, etc.)');
    } else {
      buffer.writeln('   • BLE is working perfectly!');
      buffer.writeln('   • ${results['devices_found']} device(s) discovered');
    }
    
    buffer.writeln('\n=========================');
    
    return buffer.toString();
  }
}
