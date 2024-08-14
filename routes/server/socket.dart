import 'dart:async';
import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:firedart/firedart.dart';

// Map to store device ID to WebSocket channel mapping
final deviceConnections = <String, WebSocketChannel>{};

Handler get onRequest {
  return webSocketHandler((channel, protocol) {
    String? deviceId;

    channel.stream.listen(
      (message) {
        final data = jsonDecode(message as String) as Map<String, dynamic>;

        if (data['type'] == 'register') {
          // Register the device
          deviceId = data['deviceId'] as String;
          deviceConnections[deviceId!] = channel;
          print('Device $deviceId connected');
        } else if (data['type'] == 'update') {
          // Update device status
          _updateDeviceStatus(
              data['deviceId'] as String, data['status'] as String,);
        }
      },
      onDone: () {
        if (deviceId != null) {
          deviceConnections.remove(deviceId);
          print('Device $deviceId disconnected');
        }
      },
    );

    // Send a confirmation message back to the client
    channel.sink.add(jsonEncode({'type': 'connected'}));
  });
}

Future<void> _updateDeviceStatus(String deviceId, String newStatus) async {
  final firestore = Firestore.instance;
  final devicesCollection = firestore.collection('devices');

  try {
    final querySnapshot =
        await devicesCollection.where('deviceID', isEqualTo: deviceId).get();

    if (querySnapshot.isEmpty) {
      print('Device not found: $deviceId');
      return;
    }

    final documentId = querySnapshot.first.id;
    await devicesCollection.document(documentId).update({'status': newStatus});

    print('Updated status for device $deviceId to $newStatus');

    // Notify the connected client about the status change
    final channel = deviceConnections[deviceId];
    if (channel != null) {
      channel.sink.add(jsonEncode({
        'type': 'statusUpdate',
        'deviceId': deviceId,
        'status': newStatus,
      }),);
    }
  } catch (e) {
    print('Error updating device status: $e');
  }
}
