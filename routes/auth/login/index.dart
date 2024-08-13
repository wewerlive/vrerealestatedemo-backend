import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';
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

  if (email == null || password == null) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: 'Email and password are required',
    );
  }
  final env = DotEnv(includePlatformEnvironment: true)..load();

  try {
    final user = await FirebaseAuth.instance.signIn(email, password);

    final token = JWT({
      'userId': user.id,
      'email': user.email,
    }).sign(SecretKey(env['JWT_SECRET']!));

    return Response(
      body: jsonEncode(
          {'message': 'Login successful', 'token': token, 'userId': user.id},),
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.unauthorized,
      body: jsonEncode({'error': 'Invalid credentials'}),
    );
  }
}
