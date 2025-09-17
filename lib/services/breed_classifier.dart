import 'dart:io';
import 'package:logging/logging.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'breed_classifier_interface.dart';
import 'breed_classifier_mobile.dart' if (dart.library.html) 'breed_classifier_web.dart' show createBreedClassifierImplementation;

class BreedClassifier implements BreedClassifierInterface {
  static final _log = Logger('BreedClassifier');
  final BreedClassifierInterface _impl;

  BreedClassifier._(this._impl);

  static Future<BreedClassifier> create({
    required String modelPath,
    required String labelsPath,
  }) async {
    try {
      final impl = await createBreedClassifierImplementation(modelPath: modelPath, labelsPath: labelsPath);
      return BreedClassifier._(impl);
    } catch (e) {
      _log.severe('Error creating BreedClassifier: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, String>> classifyImage(File imageFile) async {
    return _impl.classifyImage(imageFile);
  }

  @override
  Future<Interpreter> getInterpreter(String modelPath) async {
    return _impl.getInterpreter(modelPath);
  }

  @override
  void dispose() {
    _impl.dispose();
  }
}