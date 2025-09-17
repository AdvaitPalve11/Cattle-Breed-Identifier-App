import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'breed_classifier_interface.dart';

class BreedClassifierWeb implements BreedClassifierInterface {
  BreedClassifierWeb._();
  
  static Future<BreedClassifierInterface> create({
    required String modelPath,
    required String labelsPath,
  }) async {
    throw UnsupportedError('TFLite is not supported on web platform');
  }

  @override
  Future<Map<String, String>> classifyImage(File imageFile) async {
    throw UnsupportedError('TFLite is not supported on web platform');
  }

  @override
  Future<Interpreter> getInterpreter(String modelPath) async {
    throw UnsupportedError('TFLite is not supported on web platform');
  }

  @override
  void dispose() {
    // No-op for web
  }
}

// Top-level factory used by conditional imports
Future<BreedClassifierInterface> createBreedClassifierImplementation({
  required String modelPath,
  required String labelsPath,
}) async {
  return await BreedClassifierWeb.create(modelPath: modelPath, labelsPath: labelsPath);
}