import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceAssistantScreen extends StatefulWidget {
  final bool isBangla;
  const VoiceAssistantScreen({super.key, required this.isBangla});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastWords = '';
  List<Map<String, dynamic>> _conversation = [];

  // Firebase crop info
  String _cropName = '';
  String _location = '';
  String _weatherInfo = '';

  final String weatherApiKey = 'efd7529b3243b1f612734dc3664e89e4';

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _speech = stt.SpeechToText();
    _initializeTts();
    _initializeSpeech();

    _addSystemMessage(widget.isBangla
        ? 'নমস্কার! আমি আপনার কৃষি সহকারী। মাইক বাটন চাপে বাংলায় কথা বলুন।'
        : 'Hello! I am your agriculture assistant. Tap mic to speak.');

    _fetchCropBatch();
  }

  void _initializeTts() {
    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
    });
  }

  void _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'done' && _isListening) {
          _stopListening();
        }
      },
      onError: (error) {
        print('Speech error: $error');
        setState(() => _isListening = false);
      },
    );

    if (!available) {
      _addSystemMessage(widget.isBangla
          ? 'স্পিচ রিকগনিশন পাওয়া যায়নি।'
          : 'Speech recognition not available.');
    }
  }

  // Fetch crop batch info from Firebase
  Future<void> _fetchCropBatch() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('create_batches')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          _cropName = data['cropNameBn'] ?? 'ধান';
          _location = data['location'] ?? 'Dhaka';
        });
        await _fetchWeather(_location);
      } else {
        _addSystemMessage(widget.isBangla ? 'কোন ব্যাচ পাওয়া যায়নি।' : 'No crop batch found.');
      }
    } catch (e) {
      _addSystemMessage(widget.isBangla ? 'ত্রুটি ঘটেছে: $e' : 'Error: $e');
    }
  }

  // Fetch weather from OpenWeather
  Future<void> _fetchWeather(String location) async {
    try {
      final url =
          'https://api.openweathermap.org/data/2.5/weather?q=$location&appid=$weatherApiKey&units=metric';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final temp = data['main']['temp'];
        final humidity = data['main']['humidity'];
        final condition = data['weather'][0]['description'];
        setState(() {
          _weatherInfo = widget.isBangla
              ? '$location এর আবহাওয়া: $condition, তাপমাত্রা: ${temp}°C, আর্দ্রতা: ${humidity}%'
              : 'Weather in $location: $condition, Temperature: ${temp}°C, Humidity: ${humidity}%';
        });
      }
    } catch (e) {
      print('Weather fetch error: $e');
    }
  }

  void _addSystemMessage(String text, {bool isTyping = false}) {
    setState(() {
      if (isTyping) {
        _conversation.add({'text': text, 'isUser': false, 'isTyping': true, 'time': DateTime.now()});
      } else {
        if (_conversation.isNotEmpty && _conversation.last['isTyping'] == true) _conversation.removeLast();
        _conversation.add({'text': text, 'isUser': false, 'isTyping': false, 'time': DateTime.now()});
      }
    });
  }

  void _startListening() async {
    if (_isSpeaking) {
      _addSystemMessage(widget.isBangla ? 'দয়া করে কথা শেষ হওয়ার অপেক্ষা করুন' : 'Please wait for speech to finish');
      return;
    }

    bool available = await _speech.isAvailable();
    
    if (!available) {
      _addSystemMessage(widget.isBangla 
          ? 'স্পিচ রিকগনিশন পাওয়া যায়নি। ম্যানুয়ালি টাইপ করুন।'
          : 'Speech recognition not available. Type manually.');
      return;
    }

    setState(() => _isListening = true);
    
    _speech.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
        });
        
        if (result.finalResult) {
          _processUserInput(_lastWords);
        }
      },
      listenFor: Duration(seconds: 30),
      pauseFor: Duration(seconds: 3),
      partialResults: true,
      localeId: widget.isBangla ? 'bn_BD' : 'en_US',
      onSoundLevelChange: (level) {
        // Optional: Add sound level visualization if needed
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    
    if (_lastWords.isNotEmpty) {
      _processUserInput(_lastWords);
      _lastWords = '';
    }
  }

  void _processUserInput(String input) {
    if (input.trim().isEmpty) return;
    
    setState(() {
      _conversation.add({'text': input, 'isUser': true, 'time': DateTime.now()});
    });
    _addSystemMessage(widget.isBangla ? 'লিখছি...' : 'Typing...', isTyping: true);

    Future.delayed(const Duration(milliseconds: 800), () {
      _removeTypingIndicator();
      _generateResponse(input);
    });
  }

  void _removeTypingIndicator() {
    setState(() {
      if (_conversation.isNotEmpty && (_conversation.last['isTyping'] == true)) {
        _conversation.removeLast();
      }
    });
  }

  String _findBestAnswer(String input) {
    String lower = input.toLowerCase();
    if (lower.contains('আবহাওয়া') || lower.contains('weather')) {
      return _weatherInfo.isNotEmpty
          ? _weatherInfo
          : widget.isBangla
              ? 'আবহাওয়ার তথ্য পাওয়া যায়নি।'
              : 'Weather info not available.';
    }
    if (lower.contains('ধান') || lower.contains('crop')) {
      return widget.isBangla
          ? 'আপনার ফসলের নাম: $_cropName, অবস্থান: $_location'
          : 'Your crop: $_cropName, Location: $_location';
    }
    if (lower.contains('কবে কাটব') || lower.contains('harvest')) {
      return widget.isBangla
          ? 'ধান কাটার সময় সাধারণত শীষ ৮০% পেকে গেলে।'
          : 'Harvest when 80% of paddy grains are ripe.';
    }
    if (lower.contains('গুদাম') || lower.contains('storage')) {
      return widget.isBangla
          ? 'ধান শুকিয়ে গুদামে রাখুন। আর্দ্রতা ১২% এর নিচে রাখুন।'
          : 'Dry paddy before storage. Keep humidity below 12%.';
    }
    if (lower.contains('পোকা') || lower.contains('pest')) {
      return widget.isBangla
          ? 'ক্ষেত পরীক্ষা করুন। পোকা দেখা গেলে কৃষি কর্মকর্তার পরামর্শ নিন।'
          : 'Inspect field regularly. Consult agriculture officer if pests found.';
    }
    if (lower.contains('hello') || lower.contains('hi') || lower.contains('সালাম') || lower.contains('হ্যালো')) {
      return widget.isBangla
          ? 'স্বাগতম! আবহাওয়া, ফসল, বা সংরক্ষণ সম্পর্কে জিজ্ঞাসা করুন।'
          : 'Welcome! Ask about weather, crops, or storage.';
    }
    return widget.isBangla
        ? 'দুঃখিত, আমি এই প্রশ্নের উত্তর জানি না।'
        : 'Sorry, I don\'t know the answer.';
  }

  void _generateResponse(String input) async {
    final response = _findBestAnswer(input);
    _addSystemMessage(response);
    setState(() => _isSpeaking = true);

    try {
      await _flutterTts.setLanguage(widget.isBangla ? 'bn-BD' : 'en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.speak(response);
    } catch (e) {
      print('TTS error: $e');
      setState(() => _isSpeaking = false);
    }
  }

  void _handleQuickQuestion(String question) {
    _processUserInput(question);
  }

  @override
  Widget build(BuildContext context) {
    bool isBangla = widget.isBangla;

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text(
          isBangla ? 'কৃষি ভয়েস সহায়িকা' : 'Agriculture Voice Assistant',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: _conversation.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.agriculture, size: 64.sp, color: Colors.green[600]),
                        SizedBox(height: 16.h),
                        Text(isBangla ? 'মাইক বাটন চাপে কথা বলুন' : 'Tap mic button to speak',
                            style: TextStyle(color: Colors.green[800], fontSize: 16.sp, fontWeight: FontWeight.w500)),
                        SizedBox(height: 8.h),
                        Text(isBangla ? 'বাংলা বা ইংরেজিতে কথা বলুন' : 'Speak in Bangla or English',
                            style: TextStyle(color: Colors.green[600], fontSize: 14.sp)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _conversation.length,
                    itemBuilder: (context, index) => _buildChatBubble(_conversation[index], isBangla),
                  ),
          ),
          Container(
            padding: EdgeInsets.all(20.w),
            color: Colors.white,
            child: Column(
              children: [
                Text(
                  _isListening ? 
                    (isBangla ? 'কথা বলুন... $_lastWords' : 'Speak now... $_lastWords') : 
                    (isBangla ? 'মাইক বাটন চাপুন' : 'Tap mic button'),
                  style: TextStyle(
                    color: _isListening ? Colors.red : Colors.grey[700],
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 16.h),
                AvatarGlow(
                  animate: _isListening,
                  glowColor: Colors.green,
                  duration: const Duration(milliseconds: 2000),
                  repeat: true,
                  child: GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: CircleAvatar(
                      backgroundColor: _isListening ? Colors.red : Colors.green[600],
                      radius: 28.r,
                      child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white, size: 28.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> message, bool isBangla) {
    bool isUser = message['isUser'] ?? false;
    bool isTyping = message['isTyping'] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser && !isTyping)
            CircleAvatar(
              radius: 16.r,
              backgroundColor: Colors.green[100],
              child: Icon(Icons.agriculture, size: 16.sp, color: Colors.green[600]),
            ),
          SizedBox(width: 8.w),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isUser ? Colors.green[600] : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  if (!isUser) BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
                ],
              ),
              child: isTyping
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(isBangla ? 'লিখছি' : 'Typing', style: TextStyle(color: Colors.grey[600], fontSize: 14.sp)),
                        SizedBox(width: 8.w),
                        _buildTypingDots(),
                      ],
                    )
                  : Text(
                      message['text'],
                      style: TextStyle(color: isUser ? Colors.white : Colors.grey[800], fontSize: 15.sp, height: 1.4),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDots() {
    return SizedBox(
      width: 30.w,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDot(0),
          _buildDot(1),
          _buildDot(2),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      width: 6.w,
      height: 6.w,
      decoration: BoxDecoration(
        color: Colors.green[400],
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }
}