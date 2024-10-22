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
    _interpreter = await Interpreter.fromAsset('models/object.tflite');
    _inputShape = _interpreter.getInputTensor(0).shape;
    _outputShape = _interpreter.getOutputTensor(0).shape;
  }

  /// Convert Flutter [ui.Image] to a Tensor-friendly format (Byte List)
  Future<Uint8List> _preprocessImage(ui.Image image) async {
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) throw Exception('Failed to convert image to bytes.');

    return byteData.buffer.asUint8List();
  }

  Future<List<DetectedObject>> detectObjects(ui.Image image) async {
    // Ensure the model is loaded
    Uint8List? inputImageBytes;
    try {
      inputImageBytes = await _preprocessImage(image);
    } catch (e) {
      print('Error in image preprocessing: $e');
      return [];
    }

    // Resize the image to match the model input
    img.Image? decodedImage = img.decodeImage(inputImageBytes);
    if (decodedImage == null) {
      print('Failed to decode image.');
      return [];
    }

    img.Image resizedImage = img.copyResize(
      decodedImage,
      width: _inputShape[2], // Match model input width
      height: _inputShape[1], // Match model input height
    );

    Uint8List input = _imageToUint8List(resizedImage);

    var inputTensor = input.reshape([1, 448, 448, 3]); // Ensure 4D shape

    // Prepare output buffer
  var output = List<double>.filled(_outputShape[1] * _outputShape[2], 0.0); // 100 elements for [1, 25, 4]


    _interpreter.run(inputTensor, output); // inputTensor should be 4D

    try {
      _interpreter.run(input, output);
    } catch (e) {
      print('Error during model inference: $e');
      return [];
    }

    return _processOutput(output);
  }


  /// Helper method to process the raw output of the model into [DetectedObject]
  List<DetectedObject> _processOutput(List<double> output) {
    List<DetectedObject> detectedObjects = [];

    // Assuming each detection has 4 values, loop through the output
    for (int i = 0; i < output.length; i += 4) {
      if (i + 3 < output.length) {
        double x = output[i]; // X coordinate
        double y = output[i + 1]; // Y coordinate
        double width = output[i + 2]; // Width of bounding box
        double height = output[i + 3]; // Height of bounding box

        Rect boundingBox = Rect.fromLTWH(x, y, width, height);
        detectedObjects.add(
            DetectedObject(boundingBox, "Object")); // Adjust label as needed
      }
    }

    return detectedObjects;
  }


  /// Helper method to convert an [img.Image] to a Float32List (normalized pixel values)
  Float32List _imageToFloat32List(img.Image image) {
    int width = image.width;
    int height = image.height;

    Float32List input = Float32List(width * height * 3);

    int index = 0; // Track the index for the flat list
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        input[index++] = (pixel.r) / 255.0; // Red channel
        input[index++] = (pixel.g) / 255.0; // Green channel
        input[index++] = (pixel.b) / 255.0; // Blue channel
      }
    }

    return input;
  }

  /// Helper method to convert an [img.Image] to a Uint8List (8-bit pixel values)
  Uint8List _imageToUint8List(img.Image image) {
    int width = image.width;
    int height = image.height;

    // Create a Uint8List for the image data
    Uint8List input = Uint8List(width * height * 3); // 3 for RGB channels

    int index = 0; // Track the index for the flat list
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        input[index++] = pixel.r.toInt(); // Red channel
        input[index++] = pixel.g.toInt(); // Green channel
        input[index++] = pixel.b.toInt(); // Blue channel
      }
    }

    return input;
  }
}
