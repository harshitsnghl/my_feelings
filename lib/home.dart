import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:my_feelings/main.dart';
import 'package:tflite/tflite.dart';

class Home extends StatefulWidget {
  const Home({
    Key? key,
  }) : super(key: key);
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraImage? cameraImage;
  late CameraController controller;
  String output = '';

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras![0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        controller.startImageStream(
            (imageSteam) => {cameraImage = imageSteam, runModel()});
      });
    });
    loadModel();
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
      predictions!.forEach((prediction) {
        setState(() {
          output = prediction['label'];
        });
      });
    }
  }

  loadModel() async {
    await Tflite.loadModel(
        model: 'assets/model.tflite', labels: 'assets/labels.txt');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live SAFED'),
      ),
      body: Column(children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            width: MediaQuery.of(context).size.width,
            child: controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: CameraPreview(controller),
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
