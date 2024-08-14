import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firedart/firedart.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _handleGet(),
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
        // not fetching password i donno why anyone would need it but still not fetching it
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
