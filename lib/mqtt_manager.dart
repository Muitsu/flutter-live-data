// =========================================================================
//                             MQTT Manager Class
// =========================================================================

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;

// A wrapper class to manage the MQTT connection and state.
class MqttManager {
  // Use a private constructor to create a singleton instance.
  MqttManager._privateConstructor();

  // The single instance of the class.
  static final MqttManager _instance = MqttManager._privateConstructor();

  // A factory constructor to return the singleton instance.
  factory MqttManager() {
    return _instance;
  }

  // The MQTT client instance.
  late MqttServerClient client;

  // Stream controller for messages received from the broker.
  final StreamController<String> _messageStreamController =
      StreamController<String>.broadcast();

  // A public getter for the stream of messages.
  Stream<String> get messageStream => _messageStreamController.stream;

  // A public getter for the connection status.
  ValueNotifier<String> connectionStatus = ValueNotifier<String>(
    'Disconnected',
  );

  var logger = (String msg) => dev.log(name: "MqttManager", msg);

  // Method to connect to the MQTT broker with a dynamic server address and topic.
  Future<void> connect({
    required String serverAddress,
    required String topic,
  }) async {
    if (connectionStatus.value == 'Connected' ||
        connectionStatus.value == 'Subscribed') {
      logger('MqttManager: Already connected.');
      return;
    }

    // Initialize the client with the provided server address.
    final String clientId = 'flutter_app_client_123';
    client = MqttServerClient(serverAddress, clientId);
    client.logging(on: true);
    client.keepAlivePeriod = 20;

    // Set up the callbacks for connection events.
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = (subTopic) => onSubscribed(subTopic, topic);
    client.onUnsubscribed = onUnsubscribed;

    try {
      await client.connect();
    } on Exception catch (e) {
      logger('MqttManager::connect() exception: $e');
      client.disconnect();
    }

    // Update the connection status.
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      connectionStatus.value = 'Connected';
      _subscribeToTopic(topic);
    } else {
      connectionStatus.value = 'Connection failed';
    }
  }

  // Callback for successful connection.
  void onConnected() {
    logger('MqttManager::onConnected - Client connected');
  }

  // Callback for disconnection.
  void onDisconnected() {
    logger('MqttManager::onDisconnected - Client disconnected');
    connectionStatus.value = 'Disconnected';
  }

  // Callback for a successful subscription with a dynamic topic.
  void onSubscribed(String subTopic, String topic) {
    logger('MqttManager::onSubscribed - Subscribed to topic: $subTopic');
    connectionStatus.value = 'Subscribed';

    // Listen for incoming messages and add them to the stream.
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String pt = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      logger('MqttManager::Received message: $pt from topic: ${c[0].topic}');
      _messageStreamController.add('MQTT: $pt');
    });
  }

  // Callback for a successful unsubscription.
  void onUnsubscribed(String? topic) {
    logger('MqttManager::onUnsubscribed - Unsubscribed from topic: $topic');
    connectionStatus.value = 'Unsubscribed';
  }

  // Method to subscribe to the defined topic.
  void _subscribeToTopic(String topic) {
    client.subscribe(topic, MqttQos.atLeastOnce);
  }

  // Method to publish a message.
  void publish(String message, String topic) {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      logger('MqttManager::Published message: $message');
    } else {
      logger('MqttManager::Not connected. Cannot publish.');
    }
  }

  // Method to disconnect from the broker.
  void disconnect() {
    client.disconnect();
  }
}
