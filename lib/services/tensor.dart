import 'dart:ui';

import 'package:tflite_flutter/tflite_flutter.dart'; 

class DetectedObject {
  final Rect boundingBox;
  final String label;

  DetectedObject(this.boundingBox, this.label);
}

class ObjectDetectionService {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('model.tflite');
  }

  List<DetectedObject> detectObjects(/* image data */) {
    return [
      DetectedObject(const Rect.fromLTWH(100, 200, 150, 150), "Sample Object"),
    ];
  }
}
