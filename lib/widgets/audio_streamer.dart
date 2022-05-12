import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_audio/tflite_audio.dart';

class AudioStreamer extends StatefulWidget {
  const AudioStreamer({Key? key}) : super(key: key);

  @override
  State<AudioStreamer> createState() => _AudioRecorderState();
}

class _AudioRecorderState extends State<AudioStreamer> {
  //Record
  final recorder = FlutterSoundRecorder();
  bool isRecorderReady = false;

  // Playback
  final audioPlayer = AudioPlayer();
  bool isPlaying = false;

  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  String _sound = "Press the button to start";
  bool _recording = false;
  late Stream<Map<dynamic, dynamic>> result;

  @override
  void initState() {
    super.initState();
    // initRecorder();
    // setAudio();
    // initAudioPlayer();
    loadModel();
  }

  Future setAudio() async {
    audioPlayer.setReleaseMode(ReleaseMode.STOP);

    // if (file)
    //   await audioPlayer.setUrl(file, isLocal: true);
    // else {
    //   file = '/data/user/0/com.example.my_feelings/cache/audio';
    //   await audioPlayer.setUrl(file, isLocal: true);
    // }
  }

  initAudioPlayer() {
    audioPlayer.onPlayerStateChanged.listen((event) {
      setState(() {
        isPlaying = event == PlayerState.PLAYING;
      });
    });

    audioPlayer.onDurationChanged.listen((d) {
      setState(() {
        duration = d;
      });
    });

    audioPlayer.onAudioPositionChanged.listen((p) {
      setState(() {
        position = p;
      });
    });
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    audioPlayer.dispose();
    super.dispose();
  }

  Future record() async {
    audioPlayer.release();
    setState(() {
      duration = Duration.zero;
      position = Duration.zero;
    });
    if (!isRecorderReady) return;
    await recorder.startRecorder(toFile: 'audio');
  }

  Future stop() async {
    if (!isRecorderReady) return;
    final path = await recorder.stopRecorder();
    final audioFile = File(path!);
    // print("Recorded Audio File: $audioFile");
    await audioPlayer.setUrl(audioFile.path, isLocal: true);
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

  formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  loadModel() {
    TfliteAudio.loadModel(
      model: 'assets/audio/soundclassifier.tflite',
      label: 'assets/audio/labels.txt',
      numThreads: 1,
      outputRawScores: true,
      inputType: 'rawAudio',
      isAsset: true,
    );
  }

  void _recorder() {
    String recognition = "";
    if (!_recording) {
      setState(() => _recording = true);
      result = TfliteAudio.startAudioRecognition(
        numOfInferences: 5,
        detectionThreshold: 0.4,
        sampleRate: 44100,
        audioLength: 44032,
        bufferSize: 22016,
        averageWindowDuration: 1000,
        minimumTimeBetweenSamples: 30,
        suppressionTime: 1500,
      );
      result.listen((event) {
        recognition = event["recognitionResult"];
        log(event.toString());
      }).onDone(() {
        setState(() {
          _recording = false;
          _sound = recognition.split(" ")[1];
        });
      });
    }
    stop();
  }

  void _stop() {
    TfliteAudio.stopAudioRecognition();
    setState(() => _recording = false);
  }

//   runModel(audio) {
//     String recognition = "";
//     result = TfliteAudio.startFileRecognition(
//       audioDirectory: 'assets/angry.wav',
//       sampleRate: 44100,
//     );
// // //Example for advanced users who want to utilise all optional parameters from this package.
// //     result = TfliteAudio.startFileRecognition(
// //       audioDirectory: "assets/sampleAudio.wav",
// //       detectionThreshold: 0.3,
// //       averageWindowDuration: 1000,
// //       minimumTimeBetweenSamples: 30,
// //       suppressionTime: 1500,
// //       sampleRate: 44100,
// //     );
//     result.listen((event) {
//       print(event);
//       recognition = event["recognitionResult"];
//     }).onDone(() {
//       setState(() {
//         _recording = false;
//         print(recognition.split(" ")[1]);
//         _sound = recognition.split(" ")[1];
//       });
//     });
//   }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Slider(
            min: 0,
            max: duration.inSeconds.toDouble(),
            value: position.inSeconds.toDouble(),
            onChanged: (value) async {
              position = Duration(seconds: value.toInt());
              await audioPlayer.seek(position);
              // Play audio if paused
              await audioPlayer.resume();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatTime(position)),
                  Text(formatTime(duration)),
                ]),
          ),
          StreamBuilder<RecordingDisposition>(
              stream: recorder.onProgress,
              builder: (context, snapshot) {
                duration =
                    snapshot.hasData ? snapshot.data!.duration : Duration.zero;

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 32),
              CircleAvatar(
                radius: 35,
                child: IconButton(
                  icon: Icon(_recording ? Icons.pause : Icons.play_arrow),
                  // icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  iconSize: 50,
                  disabledColor: Colors.grey,
                  onPressed: recorder.isRecording
                      ? null
                      : () async {
                          if (isPlaying) {
                            await audioPlayer.pause();
                          } else {
                            String url =
                                '/data/user/0/com.example.my_feelings/cache/audio';
                            await audioPlayer.play(url, isLocal: true);
                          }
                        },
                ),
              ),
              const SizedBox(width: 32),
              CircleAvatar(
                radius: 35,
                child: IconButton(
                  icon: Icon(
                    _recording ? Icons.stop : Icons.fiber_manual_record_rounded,
                  ),
                  // icon: Icon(
                  //   recorder.isRecording
                  //       ? Icons.stop
                  //       : Icons.fiber_manual_record_rounded,
                  // ),
                  iconSize: 50,
                  onPressed: _recorder,
                  // onPressed: () async {
                  //   if (recorder.isRecording) {
                  //     await stop();
                  //   } else {recorder.isRecording
                  //     await record();
                  //   }

                  //   setState(() {});
                  // },
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
          Text(
            _sound,
            style: Theme.of(context).textTheme.headline5,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.wifi_protected_setup),
                  SizedBox(width: 8),
                  Text('Analyse Emotion'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
