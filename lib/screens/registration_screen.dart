import 'package:flutter/material.dart';
import 'package:harvestguard_bd/screens/batch_screen.dart';
import 'package:harvestguard_bd/screens/login_screen.dart';
import 'package:harvestguard_bd/services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  final bool isBangla;
  const RegistrationScreen({super.key, required this.isBangla});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  final Color _primaryColor = const Color(0xFF2E7D32);

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String result = await AuthService().register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phone: _phoneController.text.trim(),
      preferredLanguage: widget.isBangla ? "bn" : "en",
    );

    setState(() => _isLoading = false);

    if (result == "ok") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CropBatchRegistrationScreen(isBangla: widget.isBangla),
        ),
      );
    } else {
      setState(() => _errorMessage = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isBangla ? "নিবন্ধন" : "Register"),
        backgroundColor: _primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Icon(Icons.person_add, size: 90, color: _primaryColor),
              const SizedBox(height: 24),
              _field(_nameController, widget.isBangla ? "নাম" : "Name"),
              _field(_emailController, widget.isBangla ? "ইমেইল" : "Email",
                  type: TextInputType.emailAddress),
              _field(_phoneController, widget.isBangla ? "ফোন নম্বর" : "Phone",
                  type: TextInputType.phone),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: widget.isBangla ? "পাসওয়ার্ড" : "Password",
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white, // ✅ ensures text visible
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.isBangla ? "নিবন্ধন করুন" : "Register",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18), // ✅ text visible
                        ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(isBangla: widget.isBangla),
                    ),
                  );
                },
                child: Text(widget.isBangla
                    ? "অ্যাকাউন্ট আছে? লগইন করুন"
                    : "Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(labelText: label),
        validator: (value) => value!.isEmpty ? "Required" : null,
      ),
    );
  }
}
