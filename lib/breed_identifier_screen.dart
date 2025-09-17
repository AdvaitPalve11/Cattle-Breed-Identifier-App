import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/breed_classifier.dart';
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
  BreedClassifier? _classifier;

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
  }

  Future<void> _initializeClassifier() async {
    try {
      _classifier = await BreedClassifier.create(
        modelPath: 'assets/model/cattle_breed_model.tflite',
        labelsPath: 'assets/model/labels.txt',
      );
    } catch (e) {
      final trace = StackTrace.current.toString();
      setState(() {
        _error = 'Failed to initialize model: $e\n$trace';
      });
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

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _error = null;
                          });
                          await _initializeClassifier();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
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
