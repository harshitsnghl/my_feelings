import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:my_feelings/screens/analysing_screen.dart';
import 'package:my_feelings/widgets/video_streamer.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'SAFED',
        theme: ThemeData(
          primarySwatch: Colors.lime,
        ),
        debugShowCheckedModeBanner: false,
        home: const AnalysingScreen());
  }
}
