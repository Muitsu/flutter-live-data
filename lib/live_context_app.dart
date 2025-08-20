import 'package:flutter/material.dart';
import 'package:live_context/protocol_view.dart';

// The main screen with the dropdown to select the protocol.
class LiveContextApp extends StatefulWidget {
  const LiveContextApp({super.key});

  @override
  LiveContextAppState createState() => LiveContextAppState();
}

class LiveContextAppState extends State<LiveContextApp> {
  // The currently selected protocol, defaults to MQTT.
  String _selectedProtocol = 'MQTT';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Context Tester'),
        actions: [
          // A dropdown button to select the protocol.
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _selectedProtocol,
              underline: Container(), // Remove the default underline.
              style: const TextStyle(color: Colors.white, fontSize: 16),
              dropdownColor: Colors.blue,
              iconEnabledColor: Colors.white,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedProtocol = newValue;
                  });
                }
              },
              items: <String>['MQTT', 'WebSocket']
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  })
                  .toList(),
            ),
          ),
        ],
      ),
      // The body now shows the selected protocol view.
      body: ProtocolView(protocolType: _selectedProtocol),
    );
  }
}
