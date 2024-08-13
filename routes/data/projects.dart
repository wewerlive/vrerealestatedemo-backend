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
    HttpMethod.delete => _handleDelete(context),
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
                      'id': scene['id'] as String? ?? '',
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
                      'id': scene['id'] as String? ?? '',
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
        headers: {'Content-Type': 'application/json'},
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

    final scenes = data['scenes'] as List<dynamic>;
    final sceneIds = <String>{};
    for (final scene in scenes) {
      if (scene is Map<String, dynamic>) {
        if (!scene.containsKey('id')) {
          return Response(
            statusCode: HttpStatus.badRequest,
            body: jsonEncode({'error': 'All scenes must have an ID provided'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        final sceneId = scene['id'] as String;
        if (sceneIds.contains(sceneId)) {
          return Response(
            statusCode: HttpStatus.badRequest,
            body: jsonEncode(
                {'error': 'Scene IDs must be unique within an estate'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
        sceneIds.add(sceneId);
      } else {
        return Response(
          statusCode: HttpStatus.badRequest,
          body: jsonEncode({'error': 'Invalid scene data'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
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
      headers: {'Content-Type': 'application/json'},
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

    if (data.containsKey('estateName')) {
      updateData['estateName'] = data['estateName'] as String;
    }

    if (data.containsKey('status')) {
      updateData['status'] = data['status'] as String;
    }

    if (data.containsKey('scenes')) {
      final querySnapshot =
          await estatesCollection.where('estateID', isEqualTo: estateID).get();

      if (querySnapshot.isNotEmpty) {
        final existingEstate = querySnapshot.first.map;
        final existingScenes =
            (existingEstate['scenes'] as List<dynamic>?) ?? [];
        final newScenes = data['scenes'] as List<dynamic>;

        final existingSceneIds = Set<String>.from(
            existingScenes.map((scene) => scene['id'] as String));

        for (final newScene in newScenes) {
          if (newScene is Map<String, dynamic>) {
            if (!newScene.containsKey('id')) {
              return Response(
                statusCode: HttpStatus.badRequest,
                body: jsonEncode(
                    {'error': 'All scenes must have an ID provided'}),
              );
            }

            final newSceneId = newScene['id'] as String;
            if (existingSceneIds.contains(newSceneId)) {
              return Response(
                statusCode: HttpStatus.badRequest,
                body: jsonEncode(
                    {'error': 'New scene ID already exists in the estate'}),
              );
            }
            existingSceneIds.add(newSceneId);
          } else {
            return Response(
              statusCode: HttpStatus.badRequest,
              body: jsonEncode({'error': 'Invalid scene data'}),
            );
          }
        }

        updateData['scenes'] = [...existingScenes, ...newScenes];
      } else {
        return Response(
          statusCode: HttpStatus.notFound,
          body: jsonEncode({'error': 'Estate not found'}),
        );
      }
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

Future<Response> _handleDelete(RequestContext context) async {
  final firestore = Firestore.instance;
  final estatesCollection = firestore.collection('estates');

  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (!data.containsKey('estateID') || !data.containsKey('sceneID')) {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: jsonEncode(
            {'error': 'Missing required fields: estateID and sceneID'}),
      );
    }

    final estateID = data['estateID'] as String;
    final sceneID = data['sceneID'] as String;

    final querySnapshot =
        await estatesCollection.where('estateID', isEqualTo: estateID).get();

    if (querySnapshot.isEmpty) {
      return Response(
        statusCode: HttpStatus.notFound,
        body: jsonEncode({'error': 'Estate not found'}),
      );
    }

    final estateDoc = querySnapshot.first;
    final estateData = estateDoc.map;
    final scenes = estateData['scenes'] as List<dynamic>? ?? [];

    final updatedScenes =
        scenes.where((scene) => scene['id'] != sceneID).toList();

    if (scenes.length == updatedScenes.length) {
      return Response(
        statusCode: HttpStatus.notFound,
        body: jsonEncode({'error': 'Scene not found in the estate'}),
      );
    }

    await estatesCollection
        .document(estateDoc.id)
        .update({'scenes': updatedScenes});

    return Response(
      body: jsonEncode({
        'message': 'Scene deleted successfully',
        'estateID': estateID,
        'deletedSceneID': sceneID,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode({'error': 'Failed to delete scene: $e'}),
    );
  }
}
