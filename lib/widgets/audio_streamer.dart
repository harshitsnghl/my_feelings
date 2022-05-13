import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:my_feelings/controllers/emotionController.dart';
import 'package:my_feelings/models/emotion.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_audio/tflite_audio.dart';

class AudioStreamer extends ConsumerStatefulWidget {
  const AudioStreamer({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AudioStreamerState();
}

class _AudioStreamerState extends ConsumerState<AudioStreamer> {
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

  @override
  void dispose() {
    recorder.closeRecorder();
    audioPlayer.dispose();
    super.dispose();
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
      model: 'assets/soundclassifier.tflite',
      label: 'assets/labels.txt',
      numThreads: 1,
      outputRawScores: true,
      inputType: 'rawAudio',
      isAsset: true,
    ).onError((error, stackTrace) => log(error.toString()));
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
      );

      List? convert(String input) {
        List output;
        try {
          output = json.decode(input);
          return output;
        } catch (err) {
          print('The input is not a string representation of a list');
          return null;
        }
      }

      String toExact(double value) {
        var sign = "";
        if (value < 0) {
          value = -value;
          sign = "-";
        }
        var string = value.toString();
        var e = string.lastIndexOf('e');
        if (e < 0) return "$sign$string";
        assert(string.indexOf('.') == 1);
        var offset = int.parse(
            string.substring(e + (string.startsWith('-', e + 1) ? 1 : 2)));
        var digits = string.substring(0, 1) + string.substring(2, e);
        if (offset < 0) {
          return "${sign}0.${"0" * ~offset}$digits";
        }
        if (offset > 0) {
          if (offset >= digits.length) {
            return sign + digits.padRight(offset + 1, "0");
          }
          return "$sign${digits.substring(0, offset + 1)}"
              ".${digits.substring(offset + 1)}";
        }
        return digits;
      }

      int convertToInt(String e) {
        String num = (double.parse(e) * 100).toStringAsFixed(0);
        return int.parse(num);
      }

      int i = 0;
      result.listen((event) {
        if (i++ != 0) {
          recognition = event["recognitionResult"];
          List<String> recognitionStringList =
              recognition.replaceAll('[', '').replaceAll(']', '').split(",");

          List<int> recognitionList =
              recognitionStringList.map((e) => convertToInt(e)).toList();

          List<Emotion> emotionList = emotionLabels
              .asMap()
              .entries
              .map((label) => Emotion(
                    emotionLabels[label.key],
                    recognitionList[label.key],
                  ))
              .toList();

          ref.read(emotionController.notifier).update(emotionList);
        }
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

  @override
  Widget build(BuildContext context) {
    final emotions = ref.watch(emotionController);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Slider(
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _sound,
              style: Theme.of(context).textTheme.headline5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(emotions[0].emotion),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(emotions[0].value.toString()),
          )
        ],
      ),
    );
  }
}
