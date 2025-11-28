

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

void main() {
  runApp(const CropHealthScannerApp());
}

class CropHealthScannerApp extends StatelessWidget {
  const CropHealthScannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Health Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
      ),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  File? _imageFile;
  bool _isAnalyzing = false;
  String? _result;
  double? _confidence;
  final ImagePicker _picker = ImagePicker();

  // Using HuggingFace API for demonstration
  // Replace with your actual API endpoint
  static const String apiUrl = 'https://api-inference.huggingface.co/models/linkanjarad/mobilenet_v2_1.0_224-plant-disease-identification';
  static const String apiToken = 'YOUR_HUGGINGFACE_TOKEN'; // Replace with your token

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _result = null;
          _confidence = null;
        });
        
        // Automatically analyze after image selection
        _analyzeImage();
      }
    } catch (e) {
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _result = null;
      _confidence = null;
    });

    try {
      // Read and compress image
      final bytes = await _imageFile!.readAsBytes();
      
      // Optimize image size for faster upload
      final image = img.decodeImage(bytes);
      final resized = img.copyResize(image!, width: 224);
      final compressed = img.encodeJpg(resized, quality: 85);

      // Call HuggingFace API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/octet-stream',
        },
        body: compressed,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> predictions = json.decode(response.body);
        
        if (predictions.isNotEmpty) {
          // Get top prediction
          final topPrediction = predictions[0];
          final label = topPrediction['label'] as String;
          final score = topPrediction['score'] as double;

          // Simplify result to Fresh or Rotten
          final simplifiedResult = _simplifyResult(label);

          setState(() {
            _result = simplifiedResult;
            _confidence = score;
            _isAnalyzing = false;
          });
        }
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showErrorDialog('Analysis failed: $e\n\nTip: Make sure to add your HuggingFace API token');
    }
  }

  String _simplifyResult(String label) {
    // Convert detailed disease labels to simple Fresh/Rotten classification
    final lowerLabel = label.toLowerCase();
    
    if (lowerLabel.contains('healthy') || 
        lowerLabel.contains('fresh') ||
        lowerLabel == 'healthy') {
      return 'Fresh';
    } else {
      return 'Rotten';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Health Scanner'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Preview Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    height: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey[100],
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No image selected',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // Analysis Result Card
                if (_result != null || _isAnalyzing)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _isAnalyzing
                          ? Column(
                              children: const [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Analyzing crop health...',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Icon(
                                  _result == 'Fresh'
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  size: 60,
                                  color: _result == 'Fresh'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Status: $_result',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _result == 'Fresh'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Confidence: ${(_confidence! * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Action Buttons
                ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _showImageSourceDialog,
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(
                    _imageFile == null ? 'Select Image' : 'Change Image',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                if (_imageFile != null && _result == null && !_isAnalyzing)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: OutlinedButton.icon(
                      onPressed: _analyzeImage,
                      icon: const Icon(Icons.analytics),
                      label: const Text(
                        'Analyze Crop',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Info Card
                Card(
                  color: Colors.blue[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Upload a clear photo of your crop for accurate health analysis',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Alternative: Mock API implementation for testing without API key
class MockAnalysisService {
  static Future<Map<String, dynamic>> analyzeCrop() async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock response
    return {
      'result': 'Fresh',
      'confidence': 0.92,
    };
  }
}