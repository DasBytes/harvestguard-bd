import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'কৃষি সহায়িকা',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'SolaimanLipi',
      ),
      home: SpeechAgricultureAssistant(),
    );
  }
}

class SpeechAgricultureAssistant extends StatefulWidget {
  @override
  _SpeechAgricultureAssistantState createState() => _SpeechAgricultureAssistantState();
}

class _SpeechAgricultureAssistantState extends State<SpeechAgricultureAssistant> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _recognizedText = '';
  String _responseText = '';
  bool _speechAvailable = false;
  final String weatherApiKey = "efd7529b3243b1f612734dc3664e89e4";

  Map<String, dynamic>? latestBatch;

  final List<String> _commonQuestions = [
    'আজকের আবহাওয়া কেমন?',
    'আমার ধানের অবস্থা কী?',
    'গুদামে কী করব?',
    'কবে কাটব?',
    'কী সার দেব?',
    'পোকা দমনে কী করব?'
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    fetchLatestBatch();
  }

  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {},
      onError: (error) {},
    );
    setState(() {});
  }

  void _initTts() async {
    await _flutterTts.setLanguage("bn-BD");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> fetchLatestBatch() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('create_batches')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        latestBatch = snapshot.docs.first.data();
      }
    } catch (e) {
      print("Error fetching latest batch: $e");
    }
  }

  void _startListening() async {
    if (_speechAvailable && !_isListening) {
      setState(() => _isListening = true);

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });

          if (result.finalResult) {
            _processSpeech(result.recognizedWords);
          }
        },
        listenFor: Duration(seconds: 10),
        pauseFor: Duration(seconds: 3),
        localeId: 'bn_BD',
      );
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _processSpeech(String text) async {
    setState(() {
      _recognizedText = text;
    });

    String response = await _generateResponse(text);
    setState(() {
      _responseText = response;
    });

    _speakResponse(response);
  }

  Future<String> _generateResponse(String question) async {
    question = question.toLowerCase();

    if (question.contains('আবহাওয়া') || question.contains('বাদলা') || question.contains('বৃষ্টি')) {
      // Fetch weather from OpenWeather based on latest batch location
      if (latestBatch == null || latestBatch!['location'] == null) {
        return 'আমি আপনার ফসলের অবস্থান পাইনি, তাই আবহাওয়ার তথ্য দিতে পারছি না।';
      }

      String location = latestBatch!['location'];
      try {
        // Use Geocoding API to get lat/lon from location (simplified mock: assumes lat/lon stored in batch)
        double lat = latestBatch!['latitude'] ?? 23.8103;
        double lon = latestBatch!['longitude'] ?? 90.4125;

        final url =
            "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric";

        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          return 'আবহাওয়া তথ্য পাওয়া যায়নি।';
        }

        final data = jsonDecode(response.body);
        final temp = data['main']['temp'];
        final desc = data['weather'][0]['description'];
        final humidity = data['main']['humidity'];
        return 'আজকের আবহাওয়া $desc। তাপমাত্রা ${temp.toStringAsFixed(0)}°C, আর্দ্রতা $humidity%।';
      } catch (e) {
        return 'আবহাওয়া তথ্য লোডে সমস্যা: $e';
      }
    } else if (question.contains('ধান') || question.contains('ফসল') || question.contains('অবস্থা')) {
      return 'আপনার ধানের অবস্থা খুব ভালো। ধান পাকতে আর মাত্র ১০-১৫ দিন বাকি। এখন সেচ কমিয়ে দিন এবং কীটনাশক প্রয়োগ করুন।';
    } else if (question.contains('গুদাম') || question.contains('সংরক্ষণ') || question.contains('মজুত')) {
      return 'গুদামে ধান সংরক্ষণের আগে নিশ্চিত করুন ধান সম্পূর্ণ শুকনা হয়েছে। গুদাম পরিষ্কার এবং জীবাণুমুক্ত করুন। আর্দ্রতা নিয়ন্ত্রণ করুন।';
    } else if (question.contains('কাটব') || question.contains('কাটা') || question.contains('সময়')) {
      return 'ধান কাটার উপযুক্ত সময় হলো যখন ৮০% ধান পেকে গেছে। বৃষ্টি শুরু হওয়ার আগেই কাটা শেষ করুন।';
    } else if (question.contains('সার') || question.contains('উর্বরতা') || question.contains('পুষ্টি')) {
      return 'এখন ইউরিয়া সার প্রয়োগের সময়। হেক্টর প্রতি ১০০ কেজি ইউরিয়া এবং ৫০ কেজি পটাশ দিতে পারেন।';
    } else if (question.contains('পোকা') || question.contains('রোগ') || question.contains('দমন')) {
      return 'পোকা দমনে নিমের তেল বা জৈব কীটনাশক ব্যবহার করুন। সপ্তাহে একবার ফসল পরিদর্শন করুন এবং সমস্যা দেখা দিলে ব্যবস্থা নিন।';
    } else {
      return 'দুঃখিত, আমি আপনার প্রশ্নটি বুঝতে পারিনি। সাধারণ প্রশ্নগুলো হলো: আবহাওয়া, ধানের অবস্থা, গুদাম ব্যবস্থাপনা, কাটার সময়, সার প্রয়োগ, বা পোকা দমন।';
    }
  }

  void _speakResponse(String text) async {
    await _flutterTts.speak(text);
  }

  void _askQuestion(String question) {
    setState(() {
      _recognizedText = question;
    });
    _processSpeech(question);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'কৃষি ভয়েস সহায়িকা',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Voice recording section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade50, Colors.green.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.red.shade50 : Colors.green.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isListening ? Colors.red : Colors.green,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 48,
                        color: _isListening ? Colors.red : Colors.green,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      _isListening ? '🎤 শুনছি... বলুন' : '🎤 মাইক্রোফোন টিপে কথা বলুন',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    if (_recognizedText.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'আপনার প্রশ্ন:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade800,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _recognizedText,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Response section
              if (_responseText.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.blue.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.assistant,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'সহায়িকার উত্তর:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          _responseText,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 20),

              // Common questions section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade50, Colors.orange.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade200,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lightbulb,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'দ্রুত জিজ্ঞাসা করুন:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _commonQuestions.map((question) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.shade200,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => _askQuestion(question),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.orange.shade800,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                                side: BorderSide(color: Colors.orange.shade300),
                              ),
                            ),
                            child: Text(
                              question,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          onPressed: _isListening ? _stopListening : _startListening,
          backgroundColor: _isListening ? Colors.red : Colors.green.shade700,
          foregroundColor: Colors.white,
          elevation: 8,
          child: Icon(
            _isListening ? Icons.stop : Icons.mic,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }
}