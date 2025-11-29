import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "FAQ & টিম তথ্য",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= FAQ Section =================
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "প্রায়শই জিজ্ঞাসিত প্রশ্নাবলী (FAQ)",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildFAQItem(
                      "আমি কিভাবে ব্যাচ তৈরি করব?",
                      "ড্যাশবোর্ডে 'ব্যাচ তৈরি করুন' বাটনে ক্লিক করে ফসলের তথ্য পূরণ করুন।"),
                  _buildFAQItem(
                      "আমি লগইন করতে পারছি না?",
                      "সঠিক ইমেইল এবং পাসওয়ার্ড ব্যবহার করুন। যদি সমস্যা থাকে, সাপোর্টের সাথে যোগাযোগ করুন।"),
                  _buildFAQItem(
                      "ফসলের ঝুঁকি রিপোর্ট কীভাবে দেখব?",
                      "ব্যাচ নির্বাচন করার পর ড্যাশবোর্ডে ঝুঁকি সংক্ষিপ্তসার এবং পরামর্শ দেখা যাবে।"),
                  _buildFAQItem(
                      "মানচিত্রে ফসলের অবস্থান দেখার সুবিধা আছে?",
                      "হ্যাঁ, 'মানচিত্র দেখুন' বাটনে ক্লিক করলে আপনার এবং আশেপাশের ফসলের অবস্থান দেখা যাবে।"),
                ],
              ),
            ),

            // ================= Team Section =================
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.orange.shade100],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade200,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "টিম সদস্যদের তথ্য",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildTeamMember(
                      "প্রান্ত দাস",
                      "প্রজেক্ট লিড / ফ্লাটার ডেভেলপার",
                      "pranta@example.com"),
                  _buildTeamMember(
                      "সাদ সালমী",
                      "UI/UX ডিজাইনার",
                      "saad@example.com"),
                  _buildTeamMember(
                      "সাদরিব শাইয়ান ইসলাম",
                      "ব্যাকএন্ড ডেভেলপার",
                      "sadrib@example.com"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            answer,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMember(String name, String role, String email) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.orange.shade200,
            child: Icon(Icons.person, size: 32, color: Colors.orange.shade700),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
