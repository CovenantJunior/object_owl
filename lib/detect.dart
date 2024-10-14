import 'package:flutter/material.dart';
import 'package:object_owl/services/camera.dart';
import 'package:object_owl/services/tensor.dart';

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
    // Initialize camera and object detection
    await _cameraService.init();
    await _detectionService.loadModel();

    // Start detecting objects in each frame
    _startDetectionLoop();
  }

  void _startDetectionLoop() async {
    while (mounted) {
      if (_cameraService.controller != null &&
          _cameraService.controller!.value.isInitialized) {
        // Capture image from the camera
        var image = await _cameraService.controller!.takePicture();

        // Run detection on the captured image
        var objects = _detectionService.detectObjects();

        // Update state with detected objects
        setState(() {
          _detectedObjects = objects;
        });
      }
    }
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