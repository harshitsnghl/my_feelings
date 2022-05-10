import 'package:flutter/material.dart';

class Result extends StatefulWidget {
  const Result({Key? key}) : super(key: key);

  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          Text(
            'Result',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          SizedBox(height: 20),
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Text(
                  'TODO: Bar Chart with the analysis of the audio and video')),
        ],
      ),
    );
  }
}