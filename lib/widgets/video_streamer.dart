import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:my_feelings/main.dart';
import 'package:tflite/tflite.dart';

class VideoStreamer extends StatefulWidget {
  const VideoStreamer({
    Key? key,
  }) : super(key: key);
  @override
  State<VideoStreamer> createState() => _VideoStreamerState();
}

class _VideoStreamerState extends State<VideoStreamer> {
  CameraImage? cameraImage;
  late CameraController controller;
  String output = '';

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras![1], ResolutionPreset.low);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      // setState(() {
      //   controller.startImageStream(
      //       (imageSteam) => {cameraImage = imageSteam, runModel()});
      // });
    });
    // loadModel();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );
      for (var prediction in predictions!) {
        print("Prdictions" + prediction);
        setState(() {
          output = prediction['label'];
        });
      }
    }
  }

  loadModel() async {
    await Tflite.loadModel(
        model: 'assets/tflite_models/video/model.tflite',
        labels: 'assets/tflite_models/video/labels.txt');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            height: MediaQuery.of(context).size.height *
                0.5 /
                controller.value.aspectRatio,
            width: MediaQuery.of(context).size.width * 0.5,
            child: controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: CameraPreview(
                      controller,
                    ),
                  )
                : Container(),
          ),
        ),
        Text(
          output,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        )
      ]),
    );
  }
}
