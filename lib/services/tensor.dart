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
    // Preprocess the image to fit the input shape expected by the model
    Uint8List? inputImageBytes;

    try {
      inputImageBytes = await _preprocessImage(image);
    } catch (e) {
      print('Error in image preprocessing: $e');
      return [];
    }

    print('Model Input Shape: $_inputShape');
    print('Model Output Shape: $_outputShape');
    print('Decoded Image: width = ${image.width}, height = ${image.height}');

    // Decode and resize the image
    img.Image? decodedImage = img.decodeImage(inputImageBytes);
    if (decodedImage == null) {
      print('Failed to decode image.');
      return [];
    }

    img.Image resizedImage = img.copyResize(
      decodedImage,
      width: _inputShape[2], // 448
      height: _inputShape[1], // 448
    );

    // Convert the image to Float32List (normalized pixel values)
    Float32List input = _imageToFloat32List(resizedImage);

    // Prepare output buffer (adjust size based on model output)
    var output = List.generate(
      _outputShape[1] * _outputShape[2], // Adjust according to model's output
      (_) => 0.0,
    );

    // Run inference
    try {
      _interpreter.run(input, output);
    } catch (e) {
      print('Error during model inference: $e');
      return [];
    }

    // Process the output and return detected objects
    return _processOutput(output);
  }

  /// Helper method to process the raw output of the model into [DetectedObject]
  List<DetectedObject> _processOutput(List<double> output) {
    List<DetectedObject> detectedObjects = [];

    // Process each detection based on the expected output structure
    for (int i = 0; i < output.length; i += 4) {
      // Assuming each detection has 4 values
      if (i + 3 < output.length) {
        double x = output[i];
        double y = output[i + 1];
        double width = output[i + 2];
        double height = output[i + 3];

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
}
