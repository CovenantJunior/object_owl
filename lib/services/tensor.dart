import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class DetectedObject {
  final Rect boundingBox;
  final String label;

  DetectedObject(this.boundingBox, this.label);
}

class ObjectDetectionService {
  late Interpreter _interpreter;
  late List<int> _inputShape;
  late List<int> _outputShape;

  Future<void> loadModel() async {
    // Load the TensorFlow Lite model
    _interpreter = await Interpreter.fromAsset('models/model.tflite');
    _inputShape = _interpreter.getInputTensor(0).shape;
    _outputShape = _interpreter.getOutputTensor(0).shape;
  }

  /// Convert Flutter [ui.Image] to a Tensor-friendly format (Byte List)
  Future<Uint8List> _preprocessImage(ui.Image image) async {
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception('Failed to convert image to bytes.');

    return byteData.buffer.asUint8List();
  }

  /// Detect objects in the given image
  Future<List<DetectedObject>> detectObjects(ui.Image image) async {
    // Preprocess the image to fit the input shape expected by the model
    Uint8List inputImageBytes = await _preprocessImage(image);

    // Instead of decoding, resize the image to match model input size
    img.Image resizedImage = img.Image.fromBytes(
      width: _inputShape[1], 
      height: _inputShape[2], 
      bytes: inputImageBytes.buffer,
    );

    // Convert image to float32 format (as required by most TensorFlow Lite models)
    var input = _imageToFloat32List(resizedImage, _inputShape);

    // Prepare output buffer (match to your model's output shape)
    var output = List.generate(
        _outputShape[1], (_) => List<double>.filled(_outputShape[2], 0.0));

    // Run inference
    _interpreter.run(input, output);

    // Process the output and return detected objects
    return _processOutput(output);
  }


  /// Helper method to process the raw output of the model into [DetectedObject]
  List<DetectedObject> _processOutput(List<List<double>> output) {
    List<DetectedObject> detectedObjects = [];

    // Assume the output contains bounding box info and labels (adjust based on model output)
    for (var detection in output) {
      // Extract bounding box coordinates and label from the output (example format)
      double x = detection[0];
      double y = detection[1];
      double width = detection[2];
      double height = detection[3];
      String label = "Object"; // Replace with actual label mapping if available

      Rect boundingBox = Rect.fromLTWH(x, y, width, height);
      detectedObjects.add(DetectedObject(boundingBox, label));
    }

    return detectedObjects;
  }

  /// Helper method to convert an [img.Image] to a Float32List (normalized pixel values)
  List<List<List<double>>> _imageToFloat32List(
      img.Image image, List<int> inputShape) {
    List<List<List<double>>> input = List.generate(
      inputShape[1], // width
      (_) => List.generate(
        inputShape[2], // height
        (_) => List.filled(3, 0.0), // RGB channels
      ),
    );

    for (int y = 0; y < inputShape[1]; y++) {
      for (int x = 0; x < inputShape[2]; x++) {
        final pixel = image.getPixel(x, y);
        input[y][x][0] = (pixel.r) / 255.0; // Red channel
        input[y][x][1] = (pixel.g) / 255.0; // Green channel
        input[y][x][2] = (pixel.b) / 255.0; // Blue channel
      }
    }

    return input;
  }
}
