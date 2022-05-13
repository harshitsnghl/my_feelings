import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:duration_picker_dialog_box/duration_picker_dialog_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:my_feelings/controllers/emotionController.dart';
import 'package:my_feelings/maps/emojiMap.dart';
import 'package:my_feelings/models/emotion.dart';
import 'package:my_feelings/utility/convertToInt.dart';
import 'package:my_feelings/utility/formatTime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_audio/tflite_audio.dart';

class AudioStreamer extends ConsumerStatefulWidget {
  const AudioStreamer({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AudioStreamerState();
}

class _AudioStreamerState extends ConsumerState<AudioStreamer> {
  //Record
  final audioRecorder = FlutterSoundRecorder();
  bool isRecorderReady = false;

  // Playback
  final audioPlayer = AudioPlayer();
  bool isPlaying = false;

  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  String _sound = "";
  bool tfliteRecording = false;
  late Stream<Map<dynamic, dynamic>> result;

  int numberOfInference = 5;

  @override
  void initState() {
    super.initState();
    initRecorder();
    initAudioPlayer();
    setAudio();
    loadModel();
  }

  @override
  void dispose() {
    audioRecorder.closeRecorder();
    audioPlayer.dispose();
    super.dispose();
  }

  Future setAudio() async {
    audioPlayer.setReleaseMode(ReleaseMode.STOP);
    String file = '/data/user/0/com.example.my_feelings/cache/audio';
    await audioPlayer.setUrl(file, isLocal: true);
  }

  Future initRecorder() async {
    final status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    await audioRecorder.openRecorder();

    isRecorderReady = true;

    audioRecorder.setSubscriptionDuration(
      const Duration(milliseconds: 500),
    );
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
    await audioRecorder.startRecorder(toFile: 'audio');
  }

  Future stop() async {
    if (!isRecorderReady) return;
    final path = await audioRecorder.stopRecorder();
    final audioFile = File(path!);
    print("Recorded Audio File: $audioFile");
    await audioPlayer.setUrl(audioFile.path, isLocal: true);
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

  void _tfliteRecorder() {
    String recognition = "";
    List<int> recognitionList = [];

    if (!tfliteRecording) {
      record();
      setState(() => tfliteRecording = true);
      result = TfliteAudio.startAudioRecognition(
        numOfInferences: numberOfInference,
        detectionThreshold: 0.4,
        sampleRate: 44100,
        audioLength: 44032,
        bufferSize: 22016,
      );

      int i = 0;
      result.listen((event) {
        if (i != 0 &&
            i != numberOfInference - 1 &&
            i != numberOfInference - 2) {
          recognition = event["recognitionResult"];
          List<String> recognitionStringList =
              recognition.replaceAll('[', '').replaceAll(']', '').split(",");

          recognitionList =
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
        i++;
      }).onDone(() async {
        setState(() {
          tfliteRecording = false;
          _sound = getEmotionFromRawValues(recognitionList);
        });
        stop();
      });
    } else {
      tfliteRecordingStop();
      stop();
    }
  }

  String getEmotionFromRawValues(List<int> recognitionList) {
    int max = 0;
    int index = 0;
    for (int i = 0; i < recognitionList.length; i++) {
      if (recognitionList[i] > max) {
        max = recognitionList[i];
        index = i;
      }
    }
    return emotionLabels[index];
  }

  void tfliteRecordingStop() {
    TfliteAudio.stopAudioRecognition();
    setState(() => tfliteRecording = false);
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
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
                Column(
                  children: [
                    IconButton(
                      onPressed: () async => {
                        showDurationPicker(
                          context: context,
                          initialDuration: const Duration(
                            days: 0,
                            hours: 0,
                            minutes: 0,
                            seconds: 5,
                            milliseconds: 0,
                            microseconds: 0,
                          ),
                          durationPickerMode: DurationPickerMode.Second,
                        ).then((value) => {
                              setState(() {
                                numberOfInference = value!.inSeconds.toInt();
                              })
                            })
                      },
                      icon: const Icon(Icons.timer),
                    ),
                    Text(
                      numberOfInference.toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 85.0, left: 40),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatTime(position)),
                  Text(formatTime(duration)),
                ]),
          ),
          StreamBuilder<RecordingDisposition>(
              stream: audioRecorder.onProgress,
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
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  iconSize: 50,
                  disabledColor: Colors.grey,
                  onPressed: audioRecorder.isRecording
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
                    tfliteRecording
                        ? Icons.stop
                        : Icons.fiber_manual_record_rounded,
                  ),

                  iconSize: 50,
                  // onPressed: _tfliteRecorder,
                  onPressed: () async {
                    _tfliteRecorder();
                  },
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Text(
              _sound + _sound != '' ? emojiMap[_sound]! : '',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
