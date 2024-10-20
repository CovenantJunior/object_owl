import 'dart:async';
import 'dart:io'; // Import for File
import 'dart:ui' as ui; // Import for ui.Image
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:object_owl/services/camera.dart';
import 'package:object_owl/services/tensor.dart';
import 'package:image/image.dart' as img; // Import for image processing

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  final CameraService _cameraService = CameraService();
  final ObjectDetectionService _detectionService = ObjectDetectionService();
  List<DetectedObject> _detectedObjects = []; // List to hold detected objects

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
  // Initialize camera first
  await _cameraService.init();

  // Ensure the camera is initialized before loading the model
  if (_cameraService.controller != null &&
      _cameraService.controller!.value.isInitialized) {
    await _detectionService.loadModel();
    setState(() {
      
    });
    _startDetectionLoop();
  } else {
    Fluttertoast.showToast(
      msg: "Camera initialization failed",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
    );
  }
}

void _startDetectionLoop() async {
  while (mounted) {
    if (_cameraService.controller != null &&
        _cameraService.controller!.value.isInitialized) {
      // Capture image from the camera
      final XFile imageFile = await _cameraService.controller!.takePicture();

      // Convert XFile to ui.Image
      ui.Image image = await _loadImageFromFile(imageFile.path);

      // Run detection on the captured image
      var objects = await _detectionService.detectObjects(image);

      // Update state with detected objects
      setState(() {
        _detectedObjects = objects;
      });
    }
    await Future.delayed(const Duration(milliseconds: 100)); // Add delay
  }
}


  Future<ui.Image> _loadImageFromFile(String path) async {
    // Load image from file
    final data = await File(path).readAsBytes();
    
    // Decode the image to ensure it's in the right format
    final image = img.decodeImage(data);
    
    // Convert the image to ui.Image
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(data, (result) {
      completer.complete(result);
    });

    return completer.future;
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _cameraService.cameraPreview(),
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Stack(
      children: _detectedObjects.map((object) {
        return Positioned(
          left: object.boundingBox.left,
          top: object.boundingBox.top,
          child: Container(
            width: object.boundingBox.width,
            height: object.boundingBox.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: Text(
              object.label,
              style: const TextStyle(
                backgroundColor: Colors.white,
                color: Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
