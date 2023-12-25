import 'dart:async';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_localView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remoteView;
import 'package:flutter/material.dart';
import 'package:rtc/index.dart';
import 'package:rtc/utils.dart';

class Call extends StatefulWidget {
  final String channelName;
  final ClientRole clientRole;

  const Call({super.key, required this.channelName, required this.clientRole});

  @override
  State<Call> createState() => _CallState();
}

class _CallState extends State<Call> {
  final users = <int>[];
  final infoStrings = <String>[];
  bool muted = false;
  bool cameraOff = false;
  bool viewPanel = false;
  bool listView = false;
  late RtcEngine engine;

  @override
  void initState() {
    inintialize();
    super.initState();
  }

  @override
  void dispose() {
    users.clear();
    engine.leaveChannel();
    engine.destroy();
    super.dispose();
  }

  Future<void> inintialize() async {
    if (appId.isEmpty) {
      infoStrings.add('Please Provide App Id');
      infoStrings.add('Agora Engine Is Not Starting');
    }

    engine = await RtcEngine.create(appId);
    await engine.enableVideo();
    await engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await engine.setClientRole(widget.clientRole);
    agoraHandler();
    VideoEncoderConfiguration videoEncoderConfiguration =
        VideoEncoderConfiguration(
            dimensions: const VideoDimensions(width: 1920, height: 1080));
    await engine.setVideoEncoderConfiguration(videoEncoderConfiguration);
    await engine.joinChannel(token, widget.channelName, null, 0);
  }

  void agoraHandler() {
    engine.setEventHandler(RtcEngineEventHandler(
      error: (code) {
        setState(() {
          final info = 'onError: $code';
          if (code.toString() == 'ErrorCode.InvalidToken') {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                'Channel Not Found',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ));
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const IndexPage()),
                (route) => false);
          }
          infoStrings.add(info);
        });
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          final info = 'onJoinChannel: $channel, uid: $uid';
          infoStrings.add(info);
        });
      },
      leaveChannel: (stats) {
        setState(() {
          infoStrings.add('onLeaveChannel');
          users.clear();
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          final info = 'userJoined: $uid';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              '$uid Joined The Channel',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ));
          infoStrings.add(info);
          users.add(uid);
        });
      },
      userOffline: (uid, elapsed) {
        setState(() {
          final info = 'userLeft: $uid';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              '$uid Left The Channel',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ));

          infoStrings.add(info);
          users.remove(uid);
        });
      },
    ));
  }

  Widget viewRows() {
    final List<StatefulWidget> list = [];
    if (widget.clientRole == ClientRole.Broadcaster) {
      list.add(const rtc_localView.SurfaceView());
    }
    for (var uid in users) {
      list.add(rtc_remoteView.SurfaceView(
        uid: uid,
        channelId: widget.channelName,
      ));
    }
    final views = list;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: listView
          ? ListView.builder(
              itemBuilder: (context, i) => Row(
                children: [
                  Expanded(child: SizedBox(height: 200, child: views[i])),
                ],
              ),
              itemCount: views.length,
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
            )
          : Column(children: [
              Expanded(
                  child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10),
                itemBuilder: (context, i) => views[i],
                itemCount: views.length,
              ))
            ]),
    );
  }

  Widget toolBar() {
    if (widget.clientRole == ClientRole.Audience) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RawMaterialButton(
            onPressed: () {
              setState(() {
                muted = !muted;
              });
              engine.muteLocalAudioStream(muted);
            },
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: Colors.blueAccent,
            ),
          ),
          RawMaterialButton(
            onPressed: () => Navigator.pop(context),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35,
            ),
          ),
          RawMaterialButton(
              onPressed: () {
                setState(() {
                  cameraOff = !cameraOff;
                  cameraOff == true
                      ? engine.disableVideo()
                      : engine.enableVideo();
                });
              },
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white,
              padding: const EdgeInsets.all(12.0),
              child: cameraOff
                  ? const Icon(
                      Icons.videocam_off,
                      color: Colors.blueAccent,
                      size: 20,
                    )
                  : const Icon(
                      Icons.videocam,
                      color: Colors.blueAccent,
                      size: 20,
                    )),
        ],
      ),
    );
  }

  Widget pannel() {
    return Visibility(
        visible: viewPanel,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          alignment: Alignment.center,
          child: FractionallySizedBox(
            heightFactor: 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: ListView.builder(
                itemBuilder: (context, i) {
                  if (infoStrings.isEmpty) {
                    return const Text('null');
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 3,
                      horizontal: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                            child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 2, horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(infoStrings[i]),
                        ))
                      ],
                    ),
                  );
                },
                reverse: true,
                itemCount: infoStrings.length,
              ),
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Video Call',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          color: Colors.white,
          icon: const Icon(Icons.arrow_back_ios),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  viewPanel = !viewPanel;
                });
              },
              icon: const Icon(
                Icons.info_outline,
                color: Colors.white,
              )),
          IconButton(
              onPressed: () {
                setState(() {
                  listView = !listView;
                });
              },
              icon: const Icon(
                Icons.video_settings,
                color: Colors.white,
              )),
          IconButton(
              onPressed: () {
                setState(() {
                  engine.switchCamera();
                });
              },
              icon: const Icon(
                Icons.switch_camera,
                color: Colors.white,
              ))
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: [viewRows(), pannel(), toolBar()],
        ),
      ),
    );
  }
}
