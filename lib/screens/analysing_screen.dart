import 'package:flutter/material.dart';
import 'package:my_feelings/widgets/chart.dart';
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: const [
              Text('Emotion Recognizer'),
            ],
          ),
        ),
        body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: const <Widget>[
                // Text(
                //   'Speech and Facial Emotion Recognizer',
                //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                // ),
                Result(),
                SizedBox(height: 10),
                // VideoStreamer(),
                AudioStreamer(),
                SizedBox(height: 10),
              ]),
        ),
      ),
    );
  }
}
