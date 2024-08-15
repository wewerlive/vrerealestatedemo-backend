import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:firedart/auth/exceptions.dart';
import 'package:firedart/firedart.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.post => _onPost(context),
    _ => Future.value(
        Response(statusCode: HttpStatus.methodNotAllowed),
      ),
  };
}

Future<Response> _onPost(RequestContext context) async {
  final body = await context.request.body();
  final data = jsonDecode(body) as Map<String, dynamic>;

  final email = data['email'] as String?;
  final password = data['password'] as String?;
  final name = data['name'] as String?;

  if (email == null || password == null || name == null) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: 'Email, password, and name are required',
    );
  }

  try {
    final user = await FirebaseAuth.instance.signUp(email, password);

    final hashedPassword = sha256.convert(utf8.encode(password)).toString();

    final firestore = Firestore.instance;
    final userDoc = firestore.collection('users').document(hashedPassword);

    await userDoc.set({
      'id': userDoc.id, // same as hashedPassword
      'name': name,
      'email': email,
      'hashedPassword': hashedPassword,
      'createdAt': DateTime.now().toIso8601String(),
      'firebaseAuthId': user.id,
      'status': 'active',
      'updatedAt': DateTime.now().toIso8601String(),
    });

    return Response(
      statusCode: HttpStatus.created,
      body: jsonEncode({
        'message': 'User created successfully',
        'userId': userDoc.id,
        'firebaseAuthId': user.id,
      }),
    );
  } on AuthException catch (e) {
    if (e.errorCode == 'EMAIL_EXISTS') {
      return Response(
        statusCode: HttpStatus.conflict,
        body: jsonEncode({'error': 'User already exists'}),
      );
    }
    return Response(
      statusCode: HttpStatus.unauthorized,
      body: jsonEncode({'error': 'Invalid credentials'}),
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': 'Failed to create user: $e'}),
    );
  }
}
