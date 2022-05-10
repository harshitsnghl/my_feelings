import 'package:flutter/material.dart';
import 'package:my_feelings/widgets/result.dart';
import 'package:my_feelings/widgets/video_streamer.dart';
import 'package:my_feelings/widgets/audio_streamer.dart';

class AnalysingScreen extends StatefulWidget {
  const AnalysingScreen({Key? key}) : super(key: key);

  @override
  State<AnalysingScreen> createState() => _AnalysingScreenState();
}

class _AnalysingScreenState extends State<AnalysingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Recognizer'),
      ),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 20),
              Text(
                'Speech and Facial Emotion Recognition System',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 10),
              VideoStreamer(),
              AudioStreamer(),
              Result()
            ]),
      ),
    );
  }
}
