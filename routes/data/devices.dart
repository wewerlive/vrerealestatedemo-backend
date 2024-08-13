import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firedart/firedart.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _handleGet(),
    HttpMethod.post => _handlePost(context),
    HttpMethod.put => _handlePut(context),
    _ => Future.value(
        Response(statusCode: HttpStatus.methodNotAllowed),
      ),
  };
}

Future<Response> _handleGet() async {
  final firestore = Firestore.instance;
  final devicesCollection = firestore.collection('devices');

  try {
    final documents = await devicesCollection.get();
    final devices = documents.map((doc) {
      final data = doc.map;
      return {
        'deviceName': data['deviceName'] as String? ?? '',
        'deviceID': data['deviceID'] as String? ?? '',
        'status': data['status'] as String? ?? '',
        'estateIDs':
            (data['estateIDs'] as List<dynamic>?)?.cast<String>() ?? [],
      };
    }).toList();

    return Response(
      body: jsonEncode({'devices': devices}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': 'Failed to fetch devices: $e'}),
    );
  }
}

Future<Response> _handlePost(RequestContext context) async {
  final firestore = Firestore.instance;
  final devicesCollection = firestore.collection('devices');

  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (!data.containsKey('deviceName') ||
        !data.containsKey('deviceID') ||
        !data.containsKey('status') ||
        !data.containsKey('estateIDs')) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'error': 'Missing required fields'}),
      );
    }

    final deviceID = data['deviceID'] as String;

    // Check if a device with the given deviceID already exists
    final existingDevices =
        await devicesCollection.where('deviceID', isEqualTo: deviceID).get();

    if (existingDevices.isNotEmpty) {
      return Response(
        statusCode: HttpStatus.conflict,
        body: jsonEncode({
          'error': 'Device with the given deviceID already exists',
          'deviceId': existingDevices.first.id,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final estateIDs = List<String>.from(data['estateIDs'] as List);

    final newDevice = await devicesCollection.add({
      'deviceName': data['deviceName'],
      'deviceID': deviceID,
      'status': data['status'],
      'estateIDs': estateIDs,
    });

    return Response(
      statusCode: HttpStatus.created,
      body: jsonEncode({
        'message': 'Device added successfully',
        'deviceId': newDevice.id,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode(
        {'error': 'Failed to add device: $e'},
      ),
    );
  }
}

Future<Response> _handlePut(RequestContext context) async {
  final firestore = Firestore.instance;
  final devicesCollection = firestore.collection('devices');

  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (!data.containsKey('deviceID')) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'error': 'Missing required field: deviceID'}),
      );
    }

    final deviceID = data['deviceID'] as String;
    final querySnapshot =
        await devicesCollection.where('deviceID', isEqualTo: deviceID).get();

    if (querySnapshot.isEmpty) {
      return Response(
        statusCode: HttpStatus.notFound,
        body: jsonEncode({'error': 'Device not found'}),
      );
    }

    final documentId = querySnapshot.first.id;
    final updateData = <String, dynamic>{};

    if (data.containsKey('status')) {
      updateData['status'] = data['status'] as String;
    }

    if (data.containsKey('estateIDs')) {
      if (data.containsKey('estateIDs')) {
        updateData['estateIDs'] = List<String>.from(data['estateIDs'] as List);
      }
    }

    if (updateData.isNotEmpty) {
      await devicesCollection.document(documentId).update(updateData);

      return Response(
        statusCode: HttpStatus.ok,
        body: jsonEncode({
          'message': 'Device updated successfully',
          'deviceID': deviceID,
          'updatedFields': updateData.keys.toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } else {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'error': 'No fields to update'}),
      );
    }
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode(
        {'error': 'Failed to update device: $e'},
      ),
    );
  }
}
