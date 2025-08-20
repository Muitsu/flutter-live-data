import 'dart:async';

import 'package:flutter/material.dart';
import 'package:live_context/mqtt_manager.dart';
import 'package:live_context/websocket_manager.dart';

class ProtocolView extends StatefulWidget {
  final String protocolType;

  const ProtocolView({required this.protocolType, super.key});

  @override
  ProtocolViewState createState() => ProtocolViewState();
}

class ProtocolViewState extends State<ProtocolView> {
  late final TextEditingController _textController;
  late final TextEditingController _serverController;
  late final TextEditingController _topicController;
  // This variable is no longer `final` so it can be re-assigned.
  late dynamic _manager;
  StreamSubscription? _messageSubscription;
  final List<String> messages = [];

  // Reset the message list when the protocol type changes.
  @override
  void didUpdateWidget(ProtocolView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.protocolType != oldWidget.protocolType) {
      // First, cancel the old stream subscription to avoid memory leaks.
      _messageSubscription?.cancel();
      messages.clear();
      _textController.clear();
      _serverController.clear();
      _topicController.clear();

      // Update the manager and subscribe to the new stream.
      _initializeManager();
    }
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _serverController = TextEditingController();
    _topicController = TextEditingController();

    // Initialize the manager and default values based on the initial protocol.
    _initializeManager();
  }

  // A helper method to initialize the correct manager and subscribe to its stream.
  void _initializeManager() {
    if (widget.protocolType == 'MQTT') {
      _manager = MqttManager();
      _serverController.text = 'test.mosquitto.org';
      _topicController.text = 'test/topic';
    } else {
      _manager = WebSocketManager();
      _serverController.text = 'wss://echo.websocket.events';
    }

    // Listen to the message stream from the manager and update the UI.
    _messageSubscription = _manager.messageStream.listen((message) {
      setState(() {
        messages.add(message);
      });
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _textController.dispose();
    _serverController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  // Function to handle connection/disconnection.
  void _toggleConnection() {
    if (_manager.connectionStatus.value == 'Connected' ||
        _manager.connectionStatus.value == 'Subscribed') {
      _manager.disconnect();
    } else {
      final serverAddress = _serverController.text;
      if (serverAddress.isNotEmpty) {
        if (widget.protocolType == 'MQTT') {
          _manager.connect(
            serverAddress: serverAddress,
            topic: _topicController.text,
          );
        } else {
          _manager.connect(serverAddress: serverAddress);
        }
      }
    }
  }

  // Function to handle sending messages.
  void _sendMessage() {
    if (_textController.text.isNotEmpty) {
      if (widget.protocolType == 'MQTT') {
        _manager.publish(_textController.text, _topicController.text);
      } else {
        _manager.send(_textController.text);
      }
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Input field for the server address.
          TextField(
            controller: _serverController,
            decoration: const InputDecoration(
              labelText: 'Server Address',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          // Input field for the topic (only for MQTT).
          if (widget.protocolType == 'MQTT')
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'MQTT Topic',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 20),
          // Connection status and buttons
          ValueListenableBuilder<String>(
            valueListenable: _manager.connectionStatus,
            builder: (context, status, child) {
              final isConnected =
                  status == 'Connected' || status == 'Subscribed';
              return Column(
                children: [
                  Text('Status: $status', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _toggleConnection,
                    child: Text(isConnected ? 'Disconnect' : 'Connect'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // Text field for messages
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Enter message to send',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ),
            onSubmitted: (text) => _sendMessage(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Received Messages:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          // List of received messages
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(messages[index]));
              },
            ),
          ),
        ],
      ),
    );
  }
}
