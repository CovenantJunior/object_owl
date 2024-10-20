import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CameraService {
  CameraController? controller;
  List<CameraDescription>? cameras;

  // Initialize the camera asynchronously
  Future<void> init() async {
    cameras = await availableCameras();

    if (cameras!.isEmpty) {
      Fluttertoast.showToast(
          msg: "Sorry, camera access is needed. Your device has none.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red);

      Future.delayed(const Duration(seconds: 5), () {
        exit(0); // Exit the app if no cameras are available
      });
      return;
    }

    controller = CameraController(cameras![0], ResolutionPreset.ultraHigh);

    try {
      // Await the controller initialization
      await controller!.initialize();
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Error initializing the camera: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red);
    }
  }

  // Display the camera preview if initialized, otherwise show a loading spinner
  Widget cameraPreview() {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(controller!);
  }

  // Dispose of the controller when not needed
  Future<void> dispose() async {
    await controller?.dispose();
  }
}

// Stateful widget to display the camera
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraService cameraService = CameraService();
  bool isCameraReady = false;

  @override
  void initState() {
    super.initState();
    // Initialize the camera in initState
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    await cameraService.init();
    setState(() {
      isCameraReady = true; // Indicate that the camera is ready
    });
  }

  @override
  void dispose() {
    cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Preview')),
      body: isCameraReady
          ? cameraService.cameraPreview() // Display the preview if ready
          : const Center(
              child: CircularProgressIndicator()), // Show loader while waiting
    );
  }
}
