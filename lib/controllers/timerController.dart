// ignore: file_names
import 'package:flutter_riverpod/flutter_riverpod.dart';

final timerController =
    StateNotifierProvider<TimerNotifier, Duration>((ref) => TimerNotifier());

class TimerNotifier extends StateNotifier<Duration> {
  TimerNotifier() : super(Duration.zero);

  void update(Duration duration) {
    state = duration;
  }
}
