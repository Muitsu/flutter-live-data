// =========================================================================
//                             Pusher Client Wrapper
// =========================================================================

import 'dart:developer';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:http/http.dart' as http;

// A wrapper class to manage the Pusher connection and state.
class PusherService {
  // Use a private constructor to create a singleton instance.
  PusherService._privateConstructor();

  // The single instance of the class.
  static final PusherService _instance = PusherService._privateConstructor();

  // A factory constructor to return the singleton instance.
  factory PusherService() {
    return _instance;
  }

  // The Pusher client instance.
  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  // Replace with your actual Pusher credentials
  String _apiKey = 'YOUR_APP_KEY';
  String _cluster = 'YOUR_APP_CLUSTER';

  var logger = (String msg) => log(name: "PusherService", msg);

  // Method to connect to the Pusher with a dynamic channel and event.
  bool _isConnected = false;

  Future<void> connect({
    required String apiKey,
    required String cluster,
    String? authEndpoint,
    Map<String, String>? headers,
  }) async {
    if (_isConnected) {
      logger("Already connected to Pusher.");
      return;
    }

    _apiKey = apiKey;
    _cluster = cluster;

    try {
      await pusher.init(
        apiKey: _apiKey,
        cluster: _cluster,
        authEndpoint: authEndpoint,
        onAuthorizer: (channelName, socketId, options) async {
          // Optional: if you need custom auth instead of default
          // Example: manually POST to your backend
          final response = await http.post(
            Uri.parse(authEndpoint!),
            headers: headers ?? {},
            body: {"socket_id": socketId, "channel_name": channelName},
          );

          return response.body; // Must return JSON with "auth"
        },
        onConnectionStateChange: onConnectionStateChange,
        onError: onError,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onEvent: onEvent,
      );

      await pusher.connect();
      _isConnected = true;
      logger('Pusher client connected.');
    } catch (e) {
      logger('PusherService::connect() exception: $e');
      await pusher.disconnect();
      _isConnected = false;
    }
  }

  Future<void> disconnect() async {
    await pusher.disconnect();
    _isConnected = false;
    logger('Pusher client disconnected.');
  }

  // Callback for connection state changes.
  void onConnectionStateChange(dynamic currentState, dynamic previousState) {
    logger("Connection state changed: $previousState -> $currentState");
  }

  // Callback for errors.
  void onError(String message, int? code, dynamic e) {
    logger("Pusher Error: $message (Code: $code)");
  }

  // Callback for a successful subscription with a dynamic channel.
  void onSubscriptionSucceeded(String channelName, dynamic data) {
    logger("Subscription to $channelName succeeded.");
  }

  // Callback for incoming events.
  void onEvent(PusherEvent event) {
    logger(
      "Event received: ${event.eventName} on channel ${event.channelName} with data: ${event.data}",
    );
  }

  // Method to subscribe to a public channel and bind to an event.
  Future<void> subscribeToChannel({
    required String channelName,
    String? eventName,
    required Function(PusherEvent event) onListen,
  }) async {
    try {
      await pusher.subscribe(
        channelName: channelName,
        onEvent: (event) {
          if (eventName == null || event.eventName == eventName) {
            onListen(event);
          }
        },
      );
      logger("Subscribed to channel: $channelName, event: $eventName");
    } catch (e) {
      logger("Already subscribed to a channel with name $channelName");
    }
  }

  // Method to unsubscribe from a channel.
  Future<void> unsubscribeFromChannel(String channelName) async {
    await pusher.unsubscribe(channelName: channelName);
    logger("Unsubscribed from channel: $channelName");
  }
}
