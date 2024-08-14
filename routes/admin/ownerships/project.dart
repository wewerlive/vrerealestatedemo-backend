import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firedart/firedart.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.post => _handlePost(context),
    HttpMethod.get => _handleGet(context),
    _ => Future.value(
        Response(statusCode: HttpStatus.methodNotAllowed),
      ),
  };
}


Future<Response> _handleGet(RequestContext context) async {
  final firestore = Firestore.instance;
  final usersCollection = firestore.collection('users');
  final estatesCollection = firestore.collection('estates');
  // GET /admin/ownerships/project?userId=id

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

    final assignedEstateIds = (userDoc.map['assignedEstates'] as List<dynamic>?) ?? [];

    if (assignedEstateIds.isEmpty) {
      return Response(
        body: jsonEncode({
          'userId': userId,
          'assignedEstates': [],
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final assignedEstates = await Future.wait(
      assignedEstateIds.map((estateId) =>
        estatesCollection.where('estateID', isEqualTo: estateId).get()
      ),
    );

    final estateDetails = assignedEstates
      .where((estates) => estates.isNotEmpty)
      .map((estates) {
        final estate = estates.first.map;
        return {
          'estateId': estate['estateID'],
          'estateName': estate['estateName'],
          'status': estate['status'],
          'scenes': estate['scenes'],
        };
      }).toList();

    return Response(
      body: jsonEncode({
        'userId': userId,
        'assignedEstates': estateDetails,
      }),
      headers: {'Content-Type': 'application/json'},
    );

  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': 'Failed to fetch assigned estates: $e'}),
    );
  }
}


Future<Response> _handlePost(RequestContext context) async {
  final firestore = Firestore.instance;
  final usersCollection = firestore.collection('users');
  final estatesCollection = firestore.collection('estates');

  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final userId = data['userId'] as String?;
    final estateIds = data['estateIds'] as List<dynamic>?;

    if (userId == null || estateIds == null || estateIds.isEmpty) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'error': 'Missing userId or estateIds'}),
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

    final estateChecks = await Future.wait(
      estateIds.map((estateId) =>
          estatesCollection.where('estateID', isEqualTo: estateId).get()),
    );

    final nonExistentEstates = estateChecks
        .asMap()
        .entries
        .where((entry) => entry.value.isEmpty)
        .map((entry) => estateIds[entry.key])
        .toList();

    if (nonExistentEstates.isNotEmpty) {
      return Response(
        statusCode: HttpStatus.notFound,
        body: jsonEncode(
            {'error': 'Estates not found', 'estateIds': nonExistentEstates}),
      );
    }

    final currentAssignedEstates =
        (userDoc.map['assignedEstates'] as List<dynamic>?) ?? [];
    final updatedAssignedEstates = Set<String>.from(currentAssignedEstates)
      ..addAll(estateIds.cast<String>());

    await usersCollection.document(userId).update({
      'assignedEstates': updatedAssignedEstates.toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    });

    final newlyAssigned =
        estateIds.where((id) => !currentAssignedEstates.contains(id)).toList();
    final alreadyAssigned =
        estateIds.where(currentAssignedEstates.contains).toList();

    return Response(
      body: jsonEncode({
        'message': 'Estate assignment process completed',
        'newlyAssigned': newlyAssigned,
        'alreadyAssigned': alreadyAssigned,
        'totalAssigned': updatedAssignedEstates.length,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': 'Failed to assign estates: $e'}),
    );
  }
}
