// =========================================================================
//                             Pusher Client Wrapper
// =========================================================================

import 'dart:developer';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

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
  final String _apiKey = 'YOUR_APP_KEY';
  final String _cluster = 'YOUR_APP_CLUSTER';

  var logger = (String msg) => log(name: "PusherService", msg);

  // Method to connect to the Pusher with a dynamic channel and event.
  Future<void> connect({
    required String channelName,
    required String eventName,
  }) async {
    try {
      await pusher.init(
        apiKey: _apiKey,
        cluster: _cluster,
        onConnectionStateChange: onConnectionStateChange,
        onError: onError,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onEvent: onEvent,
      );
      await pusher.connect();
      logger('Pusher client connected.');
    } on Exception catch (e) {
      logger('PusherService::connect() exception: $e');
      pusher.disconnect();
    }
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
  Future<void> subscribeToChannel(
    String channelName,
    String eventName,
    Function(PusherEvent event) callback,
  ) async {
    await pusher.subscribe(
      channelName: channelName,
      onEvent: (event) {
        if (event.eventName == eventName) {
          callback(event);
        }
      },
    );
    logger("Subscribed to channel: $channelName, event: $eventName");
  }

  // Method to unsubscribe from a channel.
  Future<void> unsubscribeFromChannel(String channelName) async {
    await pusher.unsubscribe(channelName: channelName);
    logger("Unsubscribed from channel: $channelName");
  }

  // Method to disconnect from the Pusher.
  Future<void> disconnect() async {
    await pusher.disconnect();
    logger('Pusher client disconnected.');
  }
}
