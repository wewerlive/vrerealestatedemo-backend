import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import 'package:firedart/firedart.dart';

/// initializes Firebase Firestore
Middleware fireStoreMiddleware() {
  return (handler) {
    return (context) async {
      // Load environment variables
      final env = DotEnv(includePlatformEnvironment: true)..load();

      final projectId = env['FIREBASE_PROJECT_ID'];

      if (projectId == null) {
        return Response(
          statusCode: HttpStatus.internalServerError,
          body: 'Firebase credentials not found in environment variables',
        );
      }

      // Initialize Firebase if not already initialized
      if (!Firestore.initialized) {
        Firestore.initialize(projectId);
      }

      // Call the next handler
      return await handler(context);
    };
  };
}

/// initializes Firebase Auth
Middleware fireAuthMiddleware() {
  return (handler) {
    return (context) async {
      // Load environment variables
      final env = DotEnv(includePlatformEnvironment: true)..load();

      final apiKey = env['FIREBASE_API_KEY'];

      if (apiKey == null) {
        return Response(
          statusCode: HttpStatus.internalServerError,
          body: 'Firebase credentials not found in environment variables',
        );
      }

      if (!FirebaseAuth.initialized) {
        FirebaseAuth.initialize(apiKey, VolatileStore());
      }

      // Call the next handler
      return await handler(context);
    };
  };
}

/// initializes Firebase Firestore and Auth
Middleware firebaseMiddleware() {
  return (handler) {
    return (context) async {
      // Load environment variables
      final env = DotEnv(includePlatformEnvironment: true)..load();

      final apiKey = env['FIREBASE_API_KEY'];
      final projectId = env['FIREBASE_PROJECT_ID'];

      if (apiKey == null || projectId == null) {
        return Response(
          statusCode: HttpStatus.internalServerError,
          body: 'Firebase credentials not found in environment variables',
        );
      }

      if (!FirebaseAuth.initialized) {
        FirebaseAuth.initialize(apiKey, VolatileStore());
      }

      if (!Firestore.initialized) {
        Firestore.initialize(projectId);
      }

      // Call the next handler
      return await handler(context);
    };
  };
}
