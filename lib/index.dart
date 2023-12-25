import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'call.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  bool validError = false;
  ClientRole? role;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Make A Video Call',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Icon(
                  Icons.call,
                  color: Colors.white,
                  size: 150,
                ),
                const SizedBox(
                  height: 15,
                ),
                RadioListTile(
                    title: const Text(
                      'Broadcaster',
                      style: TextStyle(color: Colors.white),
                    ),
                    activeColor: Colors.amber,
                    value: ClientRole.Broadcaster,
                    groupValue: role,
                    onChanged: (ClientRole? value) {
                      setState(() {
                        role = value!;
                      });
                    }),
                RadioListTile(
                    title: const Text(
                      'Audience',
                      style: TextStyle(color: Colors.white),
                    ),
                    activeColor: Colors.amber,
                    value: ClientRole.Audience,
                    groupValue: role,
                    onChanged: (ClientRole? value) {
                      setState(() {
                        role = value!;
                      });
                    }),
                const SizedBox(
                  height: 10,
                ),
                MaterialButton(
                  onPressed: onJoin,
                  color: Colors.green,
                  shape: const StadiumBorder(),
                  child: const Text('Call',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> onJoin() async {
    if (role != null) {
      await handleCameraAndMic(Permission.camera);
      await handleCameraAndMic(Permission.microphone);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  Call(channelName: 'Flutter', clientRole: role!)));
    }
  }

  Future<void> handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
  }
}
