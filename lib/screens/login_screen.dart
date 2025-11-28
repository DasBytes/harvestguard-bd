import 'package:flutter/material.dart';
import 'package:harvestguard_bd/screens/batch_screen.dart';
import 'package:harvestguard_bd/screens/registration_screen.dart';
import 'package:harvestguard_bd/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final bool isBangla;
  const LoginScreen({super.key, required this.isBangla});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  final Color _primaryColor = const Color(0xFF2E7D32);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String result = await AuthService().login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result == "ok") {
      if (!mounted) return;
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
        title: Text(widget.isBangla ? "কৃষক লগইন" : "Farmer Login"),
        backgroundColor: _primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Icon(Icons.agriculture, size: 100, color: _primaryColor),
              const SizedBox(height: 24),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: widget.isBangla ? "ইমেইল" : "Email",
                ),
                validator: (value) => value!.isEmpty
                    ? (widget.isBangla ? "ইমেইল আবশ্যক" : "Email is required")
                    : null,
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: widget.isBangla ? "পাসওয়ার্ড" : "Password",
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) => value!.isEmpty
                    ? (widget.isBangla
                        ? "পাসওয়ার্ড আবশ্যক"
                        : "Password is required")
                    : null,
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white, // ✅ ensures text is visible
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                          widget.isBangla ? "লগইন" : "Login",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18), // ✅ text visible
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Go to Registration
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RegistrationScreen(isBangla: widget.isBangla),
                  ),
                ),
                child: Text(widget.isBangla
                    ? "অ্যাকাউন্ট নেই? রেজিস্টার করুন"
                    : "Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
