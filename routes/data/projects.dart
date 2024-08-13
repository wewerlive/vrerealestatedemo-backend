import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:firedart/firedart.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _handleGet(context),
    HttpMethod.post => _handlePost(context),
    HttpMethod.put => _handlePut(context),
    _ => Future.value(
        Response(statusCode: HttpStatus.methodNotAllowed),
      ),
  };
}

Future<Response> _handleGet(RequestContext context) async {
  final deviceID = context.request.uri.queryParameters['deviceID'];
  // data/projects?deviceID=ID001

  if (deviceID != null) {
    return _handleGetEstatesByDeviceID(deviceID);
  } else {
    return _handleGetAllEstates();
  }
}

Future<Response> _handleGetEstatesByDeviceID(String deviceID) async {
  final firestore = Firestore.instance;
  final devicesCollection = firestore.collection('devices');
  final estatesCollection = firestore.collection('estates');

  try {
    final deviceDocs =
        await devicesCollection.where('deviceID', isEqualTo: deviceID).get();
    if (deviceDocs.isEmpty) {
      return Response(
        statusCode: HttpStatus.notFound,
        body: jsonEncode({'error': 'Device not found'}),
      );
    }

    final estateIDs =
        List<String>.from(deviceDocs.first.map['estateIDs'] as List? ?? []);

    if (estateIDs.isEmpty) {
      return Response(
        body: jsonEncode({'estates': []}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final estateDocuments = await Future.wait(
      estateIDs.map(
        (id) => estatesCollection.where('estateID', isEqualTo: id).get(),
      ),
    );

    final estates = estateDocuments.expand((docs) => docs).map((doc) {
      final data = doc.map;
      return {
        'estateName': data['estateName'] as String? ?? '',
        'estateID': data['estateID'] as String? ?? '',
        'scenes': (data['scenes'] as List<dynamic>?)
                ?.map((scene) => {
                      'sceneName': scene['sceneName'] as String? ?? '',
                      'imageUrl': scene['imageUrl'] as String? ?? '',
                    })
                .toList() ??
            [],
        'status': data['status'] as String? ?? '',
      };
    }).toList();

    return Response(
      body: jsonEncode({'estates': estates}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': 'Failed to fetch estates: $e'}),
    );
  }
}

Future<Response> _handleGetAllEstates() async {
  final firestore = Firestore.instance;
  final estatesCollection = firestore.collection('estates');

  try {
    final documents = await estatesCollection.get();
    final estates = documents.map((doc) {
      final data = doc.map;
      return {
        'estateName': data['estateName'] as String? ?? '',
        'estateID': data['estateID'] as String? ?? '',
        'scenes': (data['scenes'] as List<dynamic>?)
                ?.map((scene) => {
                      'sceneName': scene['sceneName'] as String? ?? '',
                      'imageUrl': scene['imageUrl'] as String? ?? '',
                    })
                .toList() ??
            [],
        'status': data['status'] as String? ?? '',
      };
    }).toList();
    return Response(
      body: jsonEncode({'estates': estates}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': 'Failed to fetch estates: $e'}),
    );
  }
}

Future<Response> _handlePost(RequestContext context) async {
  final firestore = Firestore.instance;
  final estatesCollection = firestore.collection('estates');

  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (!data.containsKey('estateName') ||
        !data.containsKey('estateID') ||
        !data.containsKey('scenes') ||
        !data.containsKey('status')) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'error': 'Missing required fields'}),
      );
    }

    final estateID = data['estateID'] as String;

    final existingEstates =
        await estatesCollection.where('estateID', isEqualTo: estateID).get();

    if (existingEstates.isNotEmpty) {
      return Response(
        statusCode: HttpStatus.conflict,
        body: jsonEncode({
          'error': 'Estate with the given estateID already exists',
          'estateId': existingEstates.first.id,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final newEstate = await estatesCollection.add(data);
    return Response(
      statusCode: HttpStatus.created,
      body: jsonEncode({
        'message': 'Estate added successfully',
        'estateId': newEstate.id,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': 'Failed to add estate: $e'}),
    );
  }
}

Future<Response> _handlePut(RequestContext context) async {
  final firestore = Firestore.instance;
  final estatesCollection = firestore.collection('estates');

  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (!data.containsKey('estateID')) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'error': 'Missing required field: estateID'}),
      );
    }

    final estateID = data['estateID'] as String;
    final updateData = <String, dynamic>{};

    if (data.containsKey('status')) {
      updateData['status'] = data['status'] as String;
    }

    if (data.containsKey('scenes')) {
      updateData['scenes'] = data['scenes'] as List<dynamic>;
    }

    if (updateData.isEmpty) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode({'error': 'No fields to update'}),
      );
    }

    final querySnapshot =
        await estatesCollection.where('estateID', isEqualTo: estateID).get();

    if (querySnapshot.isEmpty) {
      return Response(
        statusCode: HttpStatus.notFound,
        body: jsonEncode({'error': 'Estate not found'}),
      );
    }

    final documentId = querySnapshot.first.id;
    await estatesCollection.document(documentId).update(updateData);

    return Response(
      statusCode: HttpStatus.ok,
      body: jsonEncode({
        'message': 'Estate updated successfully',
        'estateID': estateID,
        'updatedFields': updateData.keys.toList(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': 'Failed to update estate: $e'}),
    );
  }
}
