import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';

abstract class BreedClassifierInterface {
  static Future<BreedClassifierInterface> create({
    required String modelPath,
    required String labelsPath,
  }) async {
    throw UnimplementedError('Platform-specific implementation required');
  }

  Future<Map<String, String>> classifyImage(File imageFile);
  Future<Interpreter> getInterpreter(String modelPath);
  void dispose();
}