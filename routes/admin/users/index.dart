import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firedart/firedart.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _handleGet(),
    HttpMethod.put => _handlePut(context),
    _ => Future.value(
        Response(statusCode: HttpStatus.methodNotAllowed),
      ),
  };
}

Future<Response> _handleGet() async {
  final firestore = Firestore.instance;
  final usersCollection = firestore.collection('users');

  try {
    final documents = await usersCollection.get();
    final users = documents.map((doc) {
      final data = doc.map;
      return {
        'id': doc.id,
        'name': data['name'] as String? ?? '',
        'email': data['email'] as String? ?? '',
        'createdAt': data['createdAt'] as String? ?? '',
        'updatedAt': data['updatedAt'] as String? ?? '',
        'hashedPassword': data['hashedPassword'] as String? ?? '',
        'assignedEstates': data['assignedEstates'] as List<dynamic>? ?? [],
        'assignedDevices': data['assignedDevices'] as List<dynamic>? ?? [],
        'status': data['status'] as String? ?? '',
      };
    }).toList();

    return Response(
      body: jsonEncode({'users': users}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': 'Failed to fetch users: $e'}),
    );
  }
}

Future<Response> _handlePut(RequestContext context) async {
  final firestore = Firestore.instance;
  final usersCollection = firestore.collection('users');
  // PUT /admin/users?userId=123

  final userId = context.request.uri.queryParameters['userId'];
  if (userId == null) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: jsonEncode({'error': 'User ID is required'}),
    );
  }

  final requestBody = await context.request.body();
  final data = jsonDecode(requestBody) as Map<String, dynamic>;

  final estatesToUpdate =
      List<String>.from(data['estatesToUpdate'] as Iterable<dynamic>);
  final devicesToUpdate =
      List<String>.from(data['devicesToUpdate'] as Iterable<dynamic>);
  final status = data['status'] as String?;

  if (estatesToUpdate.isEmpty && devicesToUpdate.isEmpty && status == null) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: jsonEncode(
        {'error': 'No estates, devices, or status specified for update'},
      ),
    );
  }

  try {
    final Document userDoc;
    try {
      userDoc = await usersCollection.document(userId).get();
    } catch (e) {
      return Response(
        statusCode: HttpStatus.notFound,
        body: jsonEncode({'error': 'User not found'}),
      );
    }

    final currentAssignedEstates = List<String>.from(
        userDoc['assignedEstates'] as Iterable<dynamic>? ?? [],);
    final currentAssignedDevices = List<String>.from(
        userDoc['assignedDevices'] as Iterable<dynamic>? ?? [],);

    final updatedEstates = currentAssignedEstates
        .where((estateId) => !estatesToUpdate.contains(estateId))
        .toList()
      ..addAll(estatesToUpdate);

    final updatedDevices = currentAssignedDevices
        .where((deviceId) => !devicesToUpdate.contains(deviceId))
        .toList()
      ..addAll(devicesToUpdate);

    final updateData = {
      'assignedEstates': updatedEstates,
      'assignedDevices': updatedDevices,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (status != null && status != '') {
      updateData['status'] = status;
    }

    await usersCollection.document(userId).update(updateData);

    return Response(
      body: jsonEncode({
        'message': 'Successfully updated user',
        'updatedAssignedEstates': updatedEstates,
        'updatedAssignedDevices': updatedDevices,
        'status': status ?? userDoc['status'],
        'updatedAt': updateData['updatedAt'],
      }),
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': 'Failed to update user: $e'}),
    );
  }
}
