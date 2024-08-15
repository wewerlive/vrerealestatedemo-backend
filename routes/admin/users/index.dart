import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firedart/firedart.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _handleGet(),
    HttpMethod.delete => _handleDelete(context),
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
        'firebaseAuthId': data['firebaseAuthId'] as String? ?? '',
        'lastUpdated': data['lastUpdated'] as String? ?? '',
        'hashedPassword': data['hashedPassword'] as String? ?? '',
        'assignedEstates': data['assignedEstates'] as List<dynamic>? ?? [],
        'assignedDevices': data['assignedDevices'] as List<dynamic>? ?? [],
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

Future<Response> _handleDelete(RequestContext context) async {
  final firestore = Firestore.instance;
  final usersCollection = firestore.collection('users');
  // DELETE /admin/users?userId=123

  final userId = context.request.uri.queryParameters['userId'];
  if (userId == null) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: jsonEncode({'error': 'User ID is required'}),
    );
  }

  final requestBody = await context.request.body();
  final data = jsonDecode(requestBody) as Map<String, dynamic>;

  final estatesToDelete =
      List<String>.from(data['estatesToDelete'] as Iterable<dynamic>);
  final devicesToDelete =
      List<String>.from(data['devicesToDelete'] as Iterable<dynamic>);

  if (estatesToDelete.isEmpty && devicesToDelete.isEmpty) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body:
          jsonEncode({'error': 'No estates or devices specified for deletion'}),
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

    final currentAssignedEstates =
        List<String>.from(userDoc['assignedEstates'] as Iterable<dynamic>);
    final currentAssignedDevices =
        List<String>.from(userDoc['assignedDevices'] as Iterable<dynamic>);

    final updatedEstates = currentAssignedEstates
        .where((estate) => !estatesToDelete.contains(estate))
        .toList();
    final updatedDevices = currentAssignedDevices
        .where((device) => !devicesToDelete.contains(device))
        .toList();

    await usersCollection.document(userId).update({
      'assignedEstates': updatedEstates,
      'assignedDevices': updatedDevices,
    });

    return Response(
      body: jsonEncode({
        'message': 'Successfully deleted specified estates and devices',
        'updatedAssignedEstates': updatedEstates,
        'updatedAssignedDevices': updatedDevices,
      }),
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': 'Failed to delete assignments: $e'}),
    );
  }
}
