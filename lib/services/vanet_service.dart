import 'dart:async';
import 'dart:convert';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/vanet_message.dart';
import '../models/vehicle.dart';

/// VANET Simulator using Wi-Fi Direct
/// Simulates DSRC functionality for vehicle-to-vehicle communication
class VANETService {
  // Network state
  bool _isInitialized = false;
  bool _isWiFiDirectEnabled = false;
  String? _myDeviceAddress;
  
  // Message queue
  final List<VANETMessage> _messageQueue = [];
  final List<VANETMessage> _receivedMessages = [];
  
  // Message handlers
  final Map<VANETMessageType, Function(VANETMessage)> _messageHandlers = {};
  
  // Streams
  final StreamController<VANETMessage> _messageController = 
      StreamController<VANETMessage>.broadcast();
  
  Stream<VANETMessage> get messageStream => _messageController.stream;
  
  // Network info
  final NetworkInfo _networkInfo = NetworkInfo();
  
  /// Initialize VANET service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Check Wi-Fi availability
      final isWiFiEnabled = await WiFiForIoTPlugin.isEnabled();
      if (!isWiFiEnabled) {
        await WiFiForIoTPlugin.setEnabled(true);
      }
      
      // Get device address
      _myDeviceAddress = await _networkInfo.getWifiIP();
      
      _isInitialized = true;
      print('VANET Service initialized with address: $_myDeviceAddress');
      
      // Start message processing loop
      _startMessageProcessing();
    } catch (e) {
      print('Error initializing VANET Service: $e');
      // Continue without Wi-Fi Direct (degraded mode)
      _isInitialized = true;
    }
  }
  
  /// Enable Wi-Fi Direct for P2P communication
  Future<void> enableWiFiDirect() async {
    try {
      // Note: Wi-Fi Direct API is limited on mobile platforms
      // This is a simplified implementation
      
      _isWiFiDirectEnabled = true;
      print('Wi-Fi Direct enabled (simulated)');
    } catch (e) {
      print('Error enabling Wi-Fi Direct: $e');
    }
  }
  
  /// Register message handler for specific message type
  void registerMessageHandler(
    VANETMessageType type,
    Function(VANETMessage) handler,
  ) {
    _messageHandlers[type] = handler;
  }
  
  /// Send message to network
  Future<void> sendMessage(VANETMessage message) async {
    if (!_isInitialized) {
      print('VANET Service not initialized');
      return;
    }
    
    // Add to queue for broadcasting
    _messageQueue.add(message);
    
    // Immediate broadcast for critical messages
    if (message.priority == MessagePriority.critical) {
      await _broadcastMessage(message);
    }
  }
  
  /// Broadcast message via Wi-Fi
  Future<void> _broadcastMessage(VANETMessage message) async {
    try {
      // In real implementation, use UDP multicast or Wi-Fi Direct
      // For now, simulate broadcast
      
      final jsonData = jsonEncode(message.toJson());
      
      // Simulate network transmission
      // In production: Use UDP socket or Wi-Fi Direct API
      
      print('Broadcasting message: ${message.type} (${jsonData.length} bytes)');
      
      // Simulate some messages being received by calling handler
      _simulateMessageReception(message);
    } catch (e) {
      print('Error broadcasting message: $e');
    }
  }
  
  /// Simulate receiving a message (for testing)
  void _simulateMessageReception(VANETMessage message) {
    // In production, this would be called when actual network data arrives
    _handleReceivedMessage(message);
  }
  
  /// Handle received message
  void _handleReceivedMessage(VANETMessage message) {
    // Check if message is valid
    if (!message.isValid) {
      print('Dropping invalid message: ${message.id}');
      return;
    }
    
    // Check for duplicates
    if (_receivedMessages.any((m) => m.id == message.id)) {
      print('Dropping duplicate message: ${message.id}');
      return;
    }
    
    // Store message
    _receivedMessages.add(message);
    
    // Emit to stream
    _messageController.add(message);
    
    // Call registered handler
    final handler = _messageHandlers[message.type];
    handler?.call(message);
    
    // Forward message if needed
    if (message.shouldForward(_myDeviceAddress ?? 'unknown')) {
      _forwardMessage(message);
    }
    
    // Clean old messages
    _cleanOldMessages();
  }
  
  /// Forward message to other nodes
  Future<void> _forwardMessage(VANETMessage message) async {
    final forwardedMessage = message.forward(_myDeviceAddress ?? 'unknown');
    await _broadcastMessage(forwardedMessage);
  }
  
  /// Start message processing loop
  void _startMessageProcessing() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }
      
      _processMessageQueue();
    });
  }
  
  /// Process queued messages
  void _processMessageQueue() {
    if (_messageQueue.isEmpty) return;
    
    // Process high-priority messages first
    _messageQueue.sort((a, b) => 
        b.priority.index.compareTo(a.priority.index)
    );
    
    // Broadcast up to 5 messages per cycle
    final messagesToSend = _messageQueue.take(5).toList();
    
    for (final message in messagesToSend) {
      _broadcastMessage(message);
      _messageQueue.remove(message);
    }
  }
  
  /// Clean old messages from received list
  void _cleanOldMessages() {
    final now = DateTime.now();
    _receivedMessages.removeWhere((message) {
      final age = now.difference(message.timestamp).inSeconds;
      return age > 30; // Keep messages for 30 seconds
    });
  }
  
  /// Send collision warning to nearby vehicles
  Future<void> sendCollisionWarning({
    required Vehicle self,
    required String targetVehicleId,
    required double collisionRisk,
  }) async {
    final message = VANETMessage.collisionWarning(
      senderId: self.id,
      position: self.position,
      speed: self.speed,
      heading: self.heading,
      collisionRisk: collisionRisk,
      targetVehicleId: targetVehicleId,
    );
    
    await sendMessage(message);
  }
  
  /// Send cluster update
  Future<void> sendClusterUpdate({
    required String senderId,
    required String clusterId,
    required String coordinatorId,
    required int memberCount,
  }) async {
    final message = VANETMessage.clusterUpdate(
      senderId: senderId,
      clusterId: clusterId,
      coordinatorId: coordinatorId,
      memberCount: memberCount,
    );
    
    await sendMessage(message);
  }
  
  /// Send heartbeat message
  Future<void> sendHeartbeat(Vehicle self) async {
    final message = VANETMessage.heartbeat(
      senderId: self.id,
      position: self.position,
      speed: self.speed,
      heading: self.heading,
      clusterId: self.clusterId,
    );
    
    await sendMessage(message);
  }
  
  /// Get recent messages by type
  List<VANETMessage> getMessagesByType(VANETMessageType type) {
    return _receivedMessages
        .where((m) => m.type == type && m.isValid)
        .toList();
  }
  
  /// Get all received messages
  List<VANETMessage> getReceivedMessages() {
    return List.from(_receivedMessages);
  }
  
  /// Get network statistics
  Map<String, dynamic> getNetworkStats() {
    return {
      'isEnabled': _isWiFiDirectEnabled,
      'deviceAddress': _myDeviceAddress,
      'queuedMessages': _messageQueue.length,
      'receivedMessages': _receivedMessages.length,
      'messagesByType': {
        for (var type in VANETMessageType.values)
          type.toString(): _receivedMessages.where((m) => m.type == type).length,
      },
    };
  }
  
  /// Dispose resources
  void dispose() {
    _messageController.close();
    _messageQueue.clear();
    _receivedMessages.clear();
    _isInitialized = false;
  }
}
