import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class PestIdentificationService {
  Future<String> identifyPestWithGemini({
    required Uint8List imageBytes,
  }) async {
    const apiKey = "AIzaSyBJgYPi3HO8Rrd9Vz0dzadsprqbIpuglRY";

    // Using gemini-2.5-flash-preview-09-2025 model
    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=$apiKey");

    // Encode image as base64
    final imageBase64 = base64Encode(imageBytes);

    final body = {
      "contents": [
        {
          "parts": [
            {
              "text": "তুমি একজন কৃষি বিশেষজ্ঞ। ছবিটি দেখে পোকা/রোগ সনাক্ত করো, ঝুঁকি স্তর দাও (High/Medium/Low), এবং বাংলায় একটি বাস্তবসম্মত করণীয় পরিকল্পনা দাও।"
            },
            {
              "inlineData": {
                "mimeType": "image/jpeg",
                "data": imageBase64
              }
            }
          ]
        }
      ],

      // Generation configuration
      "generationConfig": {
        "temperature": 0.1, // Lower temperature for more consistent results
        "topK": 40,
        "topP": 0.8,
        "maxOutputTokens": 2048,
      },

      // Safety settings (optional but recommended)
      "safetySettings": [
        {
          "category": "HARM_CATEGORY_HARASSMENT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          "category": "HARM_CATEGORY_HATE_SPEECH",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        }
      ],

      // CORRECTED: Use google_search instead of google_search_retrieval
      "tools": [
        {
          "google_search": {}
        }
      ]
    };

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode != 200) {
        throw Exception("Gemini API Error: ${res.statusCode} - ${res.body}");
      }

      final data = jsonDecode(res.body);

      // Extract generated text with better error handling
      try {
        if (data["candidates"] != null &&
            data["candidates"].isNotEmpty &&
            data["candidates"][0]["content"] != null &&
            data["candidates"][0]["content"]["parts"] != null &&
            data["candidates"][0]["content"]["parts"].isNotEmpty) {

          final output = data["candidates"][0]["content"]["parts"][0]["text"] ?? "No output generated";
          return output;
        } else {
          throw Exception("Unexpected API response format");
        }
      } catch (e) {
        throw Exception("Failed to parse API response: $e");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }
}