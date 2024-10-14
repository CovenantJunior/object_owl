import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  CameraController? controller;
  List<CameraDescription>? cameras;

  Future<void> init() async {
    cameras = await availableCameras();
    controller = CameraController(cameras![0], ResolutionPreset.ultraHigh);
    await controller!.initialize();
  }

  Widget cameraPreview() {
    return controller != null && controller!.value.isInitialized
        ? CameraPreview(controller!)
        : const Center(child: CircularProgressIndicator());
  }

  Future<void> dispose() async {
    await controller?.dispose();
  }
}