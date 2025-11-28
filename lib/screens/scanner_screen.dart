import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  Uint8List? _imageBytes;
  bool _isLoading = false;
  String? _result;
  double? _confidence;
  final ImagePicker _picker = ImagePicker();

  // HuggingFace API endpoint - using image classification model
  static const String _apiUrl =
      'https://api-inference.huggingface.co/models/google/vit-base-patch16-224';
  static const String _apiToken = ''; // Replace with your token

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _result = null; // Clear previous result
          _confidence = null;
        });
        _analyzeImage(bytes);
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _analyzeImage(Uint8List bytes) async {
    setState(() => _isLoading = true);

    try {
      // Call HuggingFace API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/octet-stream',
        },
        body: bytes,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> predictions = jsonDecode(response.body);
        _processPredictions(predictions);
      } else {
        _showError('API Error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error analyzing image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _processPredictions(List<dynamic> predictions) {
    // Look for "Fresh" or "Rotten" labels in predictions
    String status = 'Unknown';
    double maxScore = 0;

    for (var prediction in predictions) {
      final label = prediction['label']?.toString().toLowerCase() ?? '';
      final score = (prediction['score'] as num?)?.toDouble() ?? 0;

      if (label.contains('fresh') || label.contains('rotten')) {
        if (score > maxScore) {
          maxScore = score;
          status = label.contains('fresh') ? 'Fresh' : 'Rotten';
        }
      }
    }

    setState(() {
      _result = status;
      _confidence = (maxScore * 100).round() / 100;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _result = null;
      _confidence = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Health Scanner'),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Upload a crop photo to check its health status',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Image preview container
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No image selected',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Loading indicator
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text(
                        'Analyzing crop health...',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This may take up to 30 seconds',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

              // Results card
              if (_result != null && !_isLoading) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _result == 'Fresh' ? Colors.green[50] : Colors.red[50],
                    border: Border.all(
                      color: _result == 'Fresh' ? Colors.green[700]! : Colors.red[700]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Status indicator icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _result == 'Fresh' ? Colors.green : Colors.red,
                        ),
                        child: Center(
                          child: Icon(
                            _result == 'Fresh'
                                ? Icons.check_circle_outline
                                : Icons.warning_outlined,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status text
                      Text(
                        _result == 'Fresh' ? 'Crop is Fresh ✓' : 'Crop is Rotten ✗',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _result == 'Fresh' ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Confidence score
                      Text(
                        'Confidence: ${(_confidence! * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[300],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _confidence,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _result == 'Fresh' ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Clear button
                      ElevatedButton(
                        onPressed: _clearImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Scan Another Crop'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Info card
              if (_imageBytes == null && _result == null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How it works:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Take or select a photo of your crop\n'
                        '2. AI will analyze the image\n'
                        '3. Get instant health status (Fresh/Rotten)',
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}