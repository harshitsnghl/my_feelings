import 'package:flutter/material.dart';
import 'package:my_feelings/widgets/chart.dart';

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
          SizedBox(height: 8),
          const Text('Emotion Recognition Result'),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: Chart(),
          ),
        ],
      ),
    );
  }
}
