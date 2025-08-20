// =========================================================================
//                          WebSocket Manager Class
// =========================================================================
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:developer' as dev;

// A wrapper class to manage the WebSocket connection and state.
class WebSocketManager {
  // Use a private constructor to create a singleton instance.
  WebSocketManager._privateConstructor();

  // The single instance of the class.
  static final WebSocketManager _instance =
      WebSocketManager._privateConstructor();

  // A factory constructor to return the singleton instance.
  factory WebSocketManager() {
    return _instance;
  }

  var logger = (String msg) => dev.log(name: "WebSocketManager", msg);
  // The WebSocket instance.
  WebSocket? webSocket;

  // Stream controller for messages received from the server.
  final StreamController<String> _messageStreamController =
      StreamController<String>.broadcast();

  // A public getter for the stream of messages.
  Stream<String> get messageStream => _messageStreamController.stream;

  // A public getter for the connection status.
  ValueNotifier<String> connectionStatus = ValueNotifier<String>(
    'Disconnected',
  );

  // Method to connect to the WebSocket server with a dynamic server address.
  Future<void> connect({required String serverAddress}) async {
    if (connectionStatus.value == 'Connected') {
      logger('WebSocketManager: Already connected.');
      return;
    }

    try {
      webSocket = await WebSocket.connect(serverAddress);
      connectionStatus.value = 'Connected';

      // Listen for incoming messages.
      webSocket!.listen(
        (data) {
          logger('WebSocketManager::Received message: $data');
          _messageStreamController.add('WebSocket: $data');
        },
        onDone: () {
          connectionStatus.value = 'Disconnected';
          logger('WebSocketManager::Connection closed.');
        },
        onError: (error) {
          connectionStatus.value = 'Disconnected';
          logger('WebSocketManager::Error: $error');
        },
        cancelOnError: true,
      );
    } on Exception catch (e) {
      logger('WebSocketManager::connect() exception: $e');
      connectionStatus.value = 'Connection failed';
    }
  }

  // Method to send a message.
  void send(String message) {
    if (webSocket != null && webSocket!.readyState == WebSocket.open) {
      webSocket!.add(message);
      logger('WebSocketManager::Sent message: $message');
    } else {
      logger('WebSocketManager::Not connected. Cannot send message.');
    }
  }

  // Method to disconnect.
  void disconnect() {
    if (webSocket != null) {
      webSocket!.close();
      webSocket = null;
    }
  }
}
