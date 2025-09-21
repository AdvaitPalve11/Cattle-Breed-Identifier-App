import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/breed_classifier.dart';
import '../services/db_provider.dart';
import '../models/prediction.dart';
import 'app_localizations.dart';

// Constants for image processing to improve readability and maintenance.
const double _kImageMaxWidth = 800;
const double _kImageMaxHeight = 800;
const int _kImageQuality = 85;

class BreedIdentifierScreen extends StatefulWidget {
  const BreedIdentifierScreen({super.key});

  @override
  State<BreedIdentifierScreen> createState() => _BreedIdentifierScreenState();
}

class _BreedIdentifierScreenState extends State<BreedIdentifierScreen> {
  XFile? _selectedImage;
  bool _isLoading = false;
  String _resultTitle = '';
  String _resultDescription = '';
  String? _error;
  bool _isInitializing = true;
  BreedClassifier? _classifier;

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
  }

  Future<void> _initializeClassifier() async {
    if (!mounted) return;
    setState(() => _isInitializing = true);
    try {
      _classifier = await BreedClassifier.create(
        modelPath: 'assets/model/cattle_breed_model.tflite',
        labelsPath: 'assets/model/labels.txt',
      );
    } catch (e, trace) {
      // Log the detailed error for developers, but keep the UI message simple.
      debugPrint('Failed to initialize model: $e\n$trace');
      setState(() {
        _error = AppLocalizations.of(context)?.translate('model_load_failed');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _classifier?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: _kImageMaxWidth,
      maxHeight: _kImageMaxHeight,
      imageQuality: _kImageQuality,
    );
    if (image == null) return;
    setState(() {
      _selectedImage = image;
      _resultTitle = '';
      _resultDescription = '';
      _error = null;
    });
  }

  Future<void> _identifyBreed() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.translate('no_image'))),
      );
      return;
    }

    if (_classifier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.translate('model_not_initialized'))),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _resultTitle = '';
      _resultDescription = '';
      _error = null;
    });

    try {
      final file = File(_selectedImage!.path);
      final result = await _classifier!.classifyImage(file);
      setState(() {
        _resultTitle = result['breed'] ?? 'Unknown';
        final confidenceVal = double.tryParse(result['confidence'] ?? '0.0') ?? 0.0;
        _resultDescription = 'Confidence: ${confidenceVal.toStringAsFixed(1)}%';
      });
      
      // Save the successful prediction to the database.
      _savePrediction(result, file);

    } catch (e) {
      setState(() {
        // Show a user-friendly error message instead of the raw exception.
        _error = AppLocalizations.of(context)!.translate('api_error');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Saves the prediction result and a copy of the image to the local database.
  Future<void> _savePrediction(Map<String, String> result, File imageFile) async {
    try {
      final appDoc = await getApplicationDocumentsDirectory();
      // Generate a unique filename to prevent overwriting existing images.
      final fileExtension = path.extension(imageFile.path);
      final uniqueFilename = '${const Uuid().v4()}$fileExtension';
      final targetPath = path.join(appDoc.path, 'saved_images');
      final targetDir = Directory(targetPath);
      if (!await targetDir.exists()) await targetDir.create(recursive: true);
      
      // Use copy() for more efficient file handling.
      final savedImageFile = await imageFile.copy(path.join(targetPath, uniqueFilename));

      final confidenceVal = double.tryParse(result['confidence'] ?? '') ?? 0.0;
      final prediction = Prediction(
          breed: result['breed'] ?? 'Unknown',
          confidence: confidenceVal,
          imagePath: savedImageFile.path,
          timestamp: DateTime.now().millisecondsSinceEpoch);

      final id = await DBProvider.db.insertPrediction(prediction);
      if (mounted) {
        final message = AppLocalizations.of(context)!.translate('saved_result').replaceFirst('{id}', id.toString());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (dbE, trace) {
      debugPrint('Failed to save result: $dbE\n$trace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.translate('save_error'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)?.translate('initializing_model') ?? 'Initializing model...'),
          ],
        ),
      );
    }

    if (_error != null && _classifier == null) {
      // Fatal error during initialization
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              '${AppLocalizations.of(context)?.translate('model_load_error_prefix') ?? 'Failed to load the breed identifier.'}\nError: $_error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _initializeClassifier, child: Text(AppLocalizations.of(context)?.translate('retry_button') ?? 'Retry')),
          ]),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12.0)),
                child: Text(AppLocalizations.of(context)?.translate('home_instructions') ?? 'Upload a photo of a cow or buffalo to identify its breed and get more information.', textAlign: TextAlign.center),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12.0)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: _selectedImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                              if (_isLoading)
                                Container(
                                  color: Colors.black54,
                                  child: Center(
                                      child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                        const SizedBox(height: 8),
                                        Text(AppLocalizations.of(context)?.translate('loading_text') ?? 'Analyzing image...', style: const TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(AppLocalizations.of(context)?.translate('upload_text') ?? 'Click to upload image', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.photo_library), onPressed: () => _pickImage(ImageSource.gallery)),
                  IconButton(icon: const Icon(Icons.camera_alt), onPressed: () => _pickImage(ImageSource.camera)),
                ],
              ),

              const SizedBox(height: 12),
              ElevatedButton(onPressed: _selectedImage != null && !_isLoading ? _identifyBreed : null, child: Text(AppLocalizations.of(context)!.translate('identify_button'))),

              const SizedBox(height: 16),
              if (_resultTitle.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12.0)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_resultTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(_resultDescription)]),
                ),

              // Show non-fatal errors here (e.g., classification error)
              if (_error != null && _classifier != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ],
            ],
          ),
        ),
    );
  }
}
