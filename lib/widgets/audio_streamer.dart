import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioStreamer extends StatefulWidget {
  const AudioStreamer({Key? key}) : super(key: key);

  @override
  State<AudioStreamer> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioStreamer> {
  final recorder = FlutterSoundRecorder();
  final auidoPlayer = AudioPlayer();
  bool isPlaying = false;
  bool isRecorderReady = false;

  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    initRecorder();
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    super.dispose();
  }

  Future record() async {
    if (!isRecorderReady) return;

    await recorder.startRecorder(toFile: 'audio');
  }

  Future stop() async {
    if (!isRecorderReady) return;

    final path = await recorder.stopRecorder();
    final audioFile = File(path!);
    print("Recorded Audio File: $audioFile");
  }

  Future initRecorder() async {
    final status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    await recorder.openRecorder();

    isRecorderReady = true;

    recorder.setSubscriptionDuration(
      const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<RecordingDisposition>(
                stream: recorder.onProgress,
                builder: (context, snapshot) {
                  final duration = snapshot.hasData
                      ? snapshot.data!.duration
                      : Duration.zero;

                  String twoDigits(int n) => n.toString().padLeft(2, '0');
                  final twoDigitMinutes =
                      twoDigits(duration.inMinutes.remainder(60));
                  final twoDigitSeconds =
                      twoDigits(duration.inSeconds.remainder(60));

                  return Text(
                    '$twoDigitMinutes:$twoDigitSeconds',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                }),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 32),
                ElevatedButton(
                  onPressed: () {},
                  child: const Icon(
                    Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 32),
                ElevatedButton(
                    child: Icon(
                      recorder.isRecording
                          ? Icons.stop
                          : Icons.fiber_manual_record_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      if (recorder.isRecording) {
                        await stop();
                      } else {
                        await record();
                      }

                      setState(() {});
                    }),
                const SizedBox(width: 32),
                ElevatedButton(
                  onPressed: () {},
                  child: const Icon(
                    Icons.pause,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 32),
              ],
            )
          ],
        ),
      ),
    );
  }
}
