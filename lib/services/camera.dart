import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CameraService {
  CameraController? controller;
  List<CameraDescription>? cameras;

  Future<void> init() async {
    cameras = await availableCameras();
    if (cameras!.isEmpty) {
      Fluttertoast.showToast(
        msg: "Sorry, camera access is needed. Your device has none.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red
      );
      Future.delayed(const Duration(seconds: 5), () {
        exit(0);
      });
    }
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
