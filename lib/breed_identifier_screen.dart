import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- for API key security
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

  /// Pick image from [gallery] or [camera]
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image == null) return;

    setState(() {
      _selectedImage = image;
      _resultTitle = '';
      _resultDescription = '';
    });
  }

  Future<void> _identifyBreed() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final mimeType = _selectedImage!.path.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';

      final apiKey = dotenv.env['GEMINI_API_KEY']; // Load from .env
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("Missing API key");
      }

      final Uri apiUrl = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/"
        "gemini-2.5-flash-preview-05-20:generateContent?key=$apiKey",
      );

      final response = await http.post(
        apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "Analyze this image and identify the breed of the Indian cow or buffalo. "
                          "Provide a one-paragraph description of the breed, including its primary uses "
                          "(e.g., milk, draught, dual-purpose), physical traits, and common geographical region in India. "
                          "Start the response with the breed name in bold. If you cannot determine the breed, please respond with 'Breed Unknown'."
                },
                {
                  "inlineData": {
                    "mimeType": mimeType,
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final candidates = data['candidates'];
        if (candidates == null || candidates.isEmpty) {
          throw Exception('No candidates returned from API');
        }

        final text =
            candidates[0]['content']?['parts']?[0]?['text'] ?? 'Breed Unknown';

        setState(() {
          if (text.trim() == "Breed Unknown") {
            _resultTitle =
                AppLocalizations.of(context)!.translate('breed_unknown');
            _resultDescription =
                AppLocalizations.of(context)!.translate('breed_unknown_desc');
          } else {
            // Extract bold breed name if present (**Breed**)
            final boldMatch = RegExp(r'\*\*(.*?)\*\*').firstMatch(text);
            if (boldMatch != null) {
              _resultTitle = boldMatch.group(1) ?? '';
              _resultDescription =
                  text.replaceFirst(boldMatch.group(0)!, '').trim();
            } else {
              final parts = text.split('. ');
              _resultTitle = parts.isNotEmpty ? parts[0] : '';
              _resultDescription =
                  parts.length > 1 ? parts.sublist(1).join('. ') : '';
            }
          }
        });
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('api_error'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('home_instructions'),
              style: const TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20.0),

          // Image upload area
          GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery),
            child: Container(
              width: double.infinity,
              height: 150.0,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: _selectedImage != null
                  ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload,
                            size: 48.0, color: Colors.grey),
                        const SizedBox(height: 8.0),
                        Text(AppLocalizations.of(context)!
                            .translate('upload_text')),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10.0),

          // Camera & Gallery buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.photo_library),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () => _pickImage(ImageSource.camera),
              ),
            ],
          ),
          const SizedBox(height: 20.0),

          // Identify button
          ElevatedButton(
            onPressed: _selectedImage != null && !_isLoading
                ? _identifyBreed
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50.0),
            ),
            child: Text(
                AppLocalizations.of(context)!.translate('identify_button')),
          ),
          const SizedBox(height: 20.0),

          // Loading indicator
          if (_isLoading)
            Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 10.0),
                Text(AppLocalizations.of(context)!.translate('loading_text')),
              ],
            ),

          // Results
          if (_resultTitle.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _resultTitle,
                    style: const TextStyle(
                        fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10.0),
                  Text(_resultDescription),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
