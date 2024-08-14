import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firedart/firedart.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _handleGet(context),
    HttpMethod.post => _handlePost(context),
    _ => Future.value(
        Response(statusCode: HttpStatus.methodNotAllowed),
      ),
  };
}

Future<Response> _handleGet(RequestContext context) async {
  final firestore = Firestore.instance;
  final usersCollection = firestore.collection('users');
  final devicesCollection = firestore.collection('devices');
  // GET /admin/ownerships/device?userId=id

  try {
    final userId = context.request.uri.queryParameters['userId'];

    if (userId == null) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'error': 'Missing userId parameter'}),
      );
    }

    final Document userDoc;
    try {
      userDoc = await usersCollection.document(userId).get();
    } catch (e) {
      return Response(
        statusCode: HttpStatus.notFound,
        body: jsonEncode({'error': 'User not found'}),
      );
    }

    final assignedDeviceIds =
        (userDoc.map['assignedDevices'] as List<dynamic>?) ?? [];

    if (assignedDeviceIds.isEmpty) {
      return Response(
        body: jsonEncode({
          'userId': userId,
          'assignedDevices': [],
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final assignedDevices = await Future.wait(
      assignedDeviceIds.map((deviceId) =>
          devicesCollection.where('deviceID', isEqualTo: deviceId).get()),
    );

    final deviceDetails =
        assignedDevices.where((devices) => devices.isNotEmpty).map((devices) {
      final device = devices.first.map;
      return {
        'deviceId': device['deviceID'],
        'deviceName': device['deviceName'],
        'status': device['status'],
        'estateIDs': device['estateIDs'],
      };
    }).toList();

    return Response(
      body: jsonEncode({
        'userId': userId,
        'assignedDevices': deviceDetails,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': 'Failed to fetch assigned devices: $e'}),
    );
  }
}

Future<Response> _handlePost(RequestContext context) async {
  final firestore = Firestore.instance;
  final usersCollection = firestore.collection('users');
  final devicesCollection = firestore.collection('devices');

  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final userId = data['userId'] as String?;
    final deviceIds = data['deviceIds'] as List<dynamic>?;

    if (userId == null || deviceIds == null || deviceIds.isEmpty) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'error': 'Missing userId or deviceIds'}),
      );
    }

    final Document userDoc;
    try {
      userDoc = await usersCollection.document(userId).get();
    } catch (e) {
      return Response(
        statusCode: HttpStatus.notFound,
        body: jsonEncode({'error': 'User not found'}),
      );
    }

    final deviceChecks = await Future.wait(
      deviceIds.map((deviceId) =>
          devicesCollection.where('deviceID', isEqualTo: deviceId).get()),
    );

    final nonExistentDevices = deviceChecks
        .asMap()
        .entries
        .where((entry) => entry.value.isEmpty)
        .map((entry) => deviceIds[entry.key])
        .toList();

    if (nonExistentDevices.isNotEmpty) {
      return Response(
        statusCode: HttpStatus.notFound,
        body: jsonEncode(
            {'error': 'Devices not found', 'deviceIds': nonExistentDevices}),
      );
    }

    final currentAssignedDevices =
        (userDoc.map['assignedDevices'] as List<dynamic>?) ?? [];
    final updatedAssignedDevices = Set<String>.from(currentAssignedDevices)
      ..addAll(deviceIds.cast<String>());

    await usersCollection.document(userId).update({
      'assignedDevices': updatedAssignedDevices.toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    });

    final newlyAssigned =
        deviceIds.where((id) => !currentAssignedDevices.contains(id)).toList();
    final alreadyAssigned =
        deviceIds.where(currentAssignedDevices.contains).toList();

    return Response(
      body: jsonEncode({
        'message': 'Device assignment process completed',
        'newlyAssigned': newlyAssigned,
        'alreadyAssigned': alreadyAssigned,
        'totalAssigned': updatedAssignedDevices.length,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': 'Failed to assign devices: $e'}),
    );
  }
}
