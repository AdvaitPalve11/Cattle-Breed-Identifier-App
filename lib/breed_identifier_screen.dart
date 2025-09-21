import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/breed_classifier.dart';
import '../services/db_provider.dart';
import '../models/prediction.dart';
import 'app_localizations.dart';

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
      // StackTrace is useful for debugging but not for the user.
      setState(() {
        _error = 'Failed to initialize model: $e\n$trace';
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
    final image = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
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
        const SnackBar(content: Text('Model not initialized')),
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
        _resultDescription = 'Confidence: ${result['confidence']}%';
      });
      // Save to local DB (copy image into app documents so it persists)
      try {
        final appDoc = await getApplicationDocumentsDirectory();
        final filename = path.basename(file.path);
        final targetPath = path.join(appDoc.path, 'saved_images');
        final targetDir = Directory(targetPath);
        if (!await targetDir.exists()) await targetDir.create(recursive: true);
        final targetFile = File(path.join(targetPath, filename));
        await targetFile.writeAsBytes(await file.readAsBytes());

        final confidenceVal = double.tryParse(result['confidence'] ?? '') ?? 0.0;
        final p = Prediction(breed: _resultTitle, confidence: confidenceVal, imagePath: targetFile.path, timestamp: DateTime.now().millisecondsSinceEpoch);
        final id = await DBProvider().insertPrediction(p);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved result (id: $id)')));
        }
      } catch (dbE) {
        // Non-fatal: log and show snack
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save result: $dbE')));
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.translate('api_error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing model...'),
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
            Text('Failed to load the breed identifier. Please check your connection and try again. Error: $_error', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _initializeClassifier, child: const Text('Retry')),
          ]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.translate('app_name') ?? 'Cattle Breed App'),
      ),
      body: SafeArea(
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
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    'An error occurred during identification: $_error',
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
