import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firedart/firedart.dart';

/// initializes Firebase Firestore
Middleware fireStoreMiddleware() {
  return (handler) {
    return (context) async {
      // Load environment variables
      final env = Platform.environment['FIREBASE_PROJECT_ID'];

      final projectId = env;

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
      final env = Platform.environment['FIREBASE_API_KEY'];

      final apiKey = env;

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
      final envKey = Platform.environment['FIREBASE_API_KEY'];
      final envId = Platform.environment['FIREBASE_PROJECT_ID'];

      final apiKey = envKey;
      final projectId = envId;

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
