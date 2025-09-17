import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:logging/logging.dart';
import 'breed_classifier_interface.dart';

class BreedClassifierMobile implements BreedClassifierInterface {
  static final _log = Logger('BreedClassifierMobile');
  late final Interpreter _interpreter;
  late final List<String> _labels;
  
  // Input image size required by the model
  static const int inputSize = 224;
  
  BreedClassifierMobile._();
  
  static Future<BreedClassifierInterface> create({
    required String modelPath,
    required String labelsPath,
  }) async {
    try {
      final instance = BreedClassifierMobile._();
      
      // Load model (try multiple strategies for robustness)
      try {
        instance._interpreter = await instance.getInterpreter(modelPath);
      } catch (e) {
        _log.warning('Failed to load interpreter from provided path ($modelPath): $e');
        // Try filename-only (some plugins expect just the filename)
        final filename = modelPath.split('/').last;
        try {
          instance._interpreter = await instance.getInterpreter(filename);
        } catch (e2) {
          _log.warning('Failed to load interpreter from filename ($filename): $e2');
          // Fallback: copy asset bytes to a temp file and load from file
          try {
            _log.info('Attempting to load model by writing asset bytes to a temporary file');
            final bytes = await rootBundle.load(modelPath);
            final tempDir = Directory.systemTemp;
            final tempFile = File('${tempDir.path}/$filename');
            await tempFile.writeAsBytes(bytes.buffer.asUint8List());
            instance._interpreter = Interpreter.fromFile(tempFile);
          } catch (e3) {
            _log.severe('All model loading strategies failed: $e3');
            rethrow;
          }
        }
      }

      // Allocate tensors and log input/output tensor details
      try {
        instance._interpreter.allocateTensors();
        final inputTensor = instance._interpreter.getInputTensor(0);
        final outputTensor = instance._interpreter.getOutputTensor(0);
        _log.info('Interpreter input shape: ${inputTensor.shape}, dtype: ${inputTensor.type}');
        _log.info('Interpreter output shape: ${outputTensor.shape}, dtype: ${outputTensor.type}');
      } catch (e) {
        _log.warning('Warning when allocating tensors or reading tensor info: $e');
      }
      
      // Load labels from assets via rootBundle
      final labelsContent = await rootBundle.loadString(labelsPath);
      instance._labels = labelsContent.split('\n').where((s) => s.isNotEmpty).toList();
      
      _log.info('Model and labels loaded successfully');
      _log.info('Number of classes: ${instance._labels.length}');
      
      return instance;
    } catch (e) {
      _log.severe('Error creating BreedClassifierMobile: $e');
      rethrow;
    }
  }

  @override
  Future<Interpreter> getInterpreter(String modelPath) async {
    try {
      _log.info('Loading interpreter from asset: $modelPath');
      return Interpreter.fromAsset(modelPath);
    } catch (e) {
      _log.severe('Error loading interpreter: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, String>> classifyImage(File imageFile) async {
    try {
      // Load and preprocess the image
      final image = img.decodeImage(await imageFile.readAsBytes());
      if (image == null) throw Exception('Failed to load image');
      
      // Resize image to match model input size
      final resized = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.linear,
      );
      
      // Build 4D List input [1, inputSize, inputSize, 3] (NHWC)
      final input = List.generate(1, (_) => List.generate(inputSize, (_) => List.generate(inputSize, (_) => List.filled(3, 0.0))));
      for (var y = 0; y < inputSize; y++) {
        for (var x = 0; x < inputSize; x++) {
          final pixel = resized.getPixel(x, y);
          // pixel is a Pixel object from package:image; use its r/g/b properties
          final r = (pixel.r) / 255.0;
          final g = (pixel.g) / 255.0;
          final b = (pixel.b) / 255.0;
          input[0][y][x][0] = r;
          input[0][y][x][1] = g;
          input[0][y][x][2] = b;
        }
      }

      // Prepare output buffer according to model output shape
      final outputTensor = _interpreter.getOutputTensor(0);
      final outShape = outputTensor.shape;
      final numClasses = outShape.length >= 2 ? outShape.last : outShape.reduce((a, b) => a * b);
      final List<List<double>> output = List.generate(1, (_) => List.filled(numClasses, 0.0));

      // Run inference
      _interpreter.run(input, output);

      // Find max score
      double maxScore = -double.infinity;
      int maxIndex = 0;
      for (var i = 0; i < numClasses; i++) {
        final double score = output[0][i];
        if (score > maxScore) {
          maxScore = score;
          maxIndex = i;
        }
      }

      final confidence = (maxScore * 100).toStringAsFixed(1);
      final breed = _labels.isNotEmpty ? _labels[maxIndex] : 'Unknown';
      _log.info('Classified as: $breed ($confidence%)');
      return {'breed': breed, 'confidence': confidence};
    } catch (e) {
      _log.severe('Error during classification: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _interpreter.close();
  }

  // Debug helper: try to load the model and print tensor info. Returns true on success.
  static Future<bool> debugTryLoadModel(String modelPath) async {
    try {
      final interpreter = await Interpreter.fromAsset(modelPath);
      try {
        interpreter.allocateTensors();
        final input = interpreter.getInputTensor(0);
        final output = interpreter.getOutputTensor(0);
        _log.info('[debugTryLoadModel] input shape: ${input.shape}, type: ${input.type}');
        _log.info('[debugTryLoadModel] output shape: ${output.shape}, type: ${output.type}');
      } catch (e) {
        _log.warning('[debugTryLoadModel] allocate/read tensors failed: $e');
      }
      interpreter.close();
      return true;
    } catch (e) {
      _log.severe('[debugTryLoadModel] failed to load model: $e');
      return false;
    }
  }
}

// Top-level factory used by conditional imports
Future<BreedClassifierInterface> createBreedClassifierImplementation({
  required String modelPath,
  required String labelsPath,
}) async {
  return await BreedClassifierMobile.create(modelPath: modelPath, labelsPath: labelsPath);
}

