// ignore: file_names
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_feelings/models/emotion.dart';

final emotionController = StateNotifierProvider<CounterNotifier, List<Emotion>>(
    (ref) => CounterNotifier());

class CounterNotifier extends StateNotifier<List<Emotion>> {
  CounterNotifier()
      : super([
          Emotion(emotionLabels[0], 0),
          Emotion(emotionLabels[1], 0),
          Emotion(emotionLabels[2], 0),
          Emotion(emotionLabels[3], 0),
          Emotion(emotionLabels[4], 0),
          Emotion(emotionLabels[5], 0),
          Emotion(emotionLabels[6], 0),
          Emotion(emotionLabels[7], 0),
        ]);

  void update(List<Emotion> emotion) {
    state = emotion;
  }
}
