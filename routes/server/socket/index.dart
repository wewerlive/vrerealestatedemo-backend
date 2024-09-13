import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:logging/logging.dart';

final connectedClients = <WebSocketChannel>[];
String currentScene = '';
String currentLocation = '';
String previousScene = '';
String previousLocation = '';

// Create a logger
final logger = Logger('WebSocketServer');

Future<Response> onRequest(RequestContext context) async {
  // Set up logging
  Logger.root.level = Level.ALL;

  final handler = webSocketHandler((channel, protocol) {
    connectedClients.add(channel);

    channel.stream.listen(
      (message) {
        handleClientMessage(channel, message);
      },
      onDone: () {
        connectedClients.remove(channel);
        logStatus();
      },
    );

    logStatus();
  });

  return handler(context);
}

void handleClientMessage(WebSocketChannel client, dynamic message) {
  logger.info('Received message from client: $message');

  if (message is String) {
    if (message.startsWith('s')) {
      handleSceneChange(message);
    } else if (message.startsWith('t')) {
      handleLocationChange(message);
    }
  }
}

void handleSceneChange(String newScene) {
  if (newScene != currentScene) {
    previousScene = currentScene;
    currentScene = newScene;
    broadcastChange('sceneChanged', newScene);
    logStatus();
  }
}

void handleLocationChange(String newLocation) {
  if (newLocation != currentLocation) {
    previousLocation = currentLocation;
    currentLocation = newLocation;
    broadcastChange('locationChanged', newLocation);
    logStatus();
  }
}

void broadcastChange(String changeType, String newValue) {
  logger.info('Broadcasting $changeType: $newValue');
  for (final client in connectedClients) {
    client.sink.add('$newValue');
  }
}

void logStatus() {
  final statusTable = '''
==================================================
| Status Update                                  |
==================================================
| Connections: ${connectedClients.length.toString().padRight(33)} |
| Current Scene: ${currentScene.padRight(31)} |
| Current Location: ${currentLocation.padRight(28)} |
==================================================
''';
  logger.info('\n$statusTable');
}
