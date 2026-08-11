import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SignupPage extends StatefulWidget {
  final bool isFarmer;
  const SignupPage({super.key, required this.isFarmer});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signup() async {
    // 1. Basic Validation
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar("Password must be at least 6 characters");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Using the unified signUp method from AuthService
      final user = await _auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        isFarmer: widget.isFarmer, // Passes the role chosen at LandingPage
      );

      if (user != null && mounted) {
        // 3. Return to Login Page on success
        Navigator.pop(context);
        _showSnackBar("Registration Successful! Please Login.", isError: false);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Registration failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Green for Farmers, Orange for Customers
    final themeColor = widget.isFarmer
        ? Colors.green.shade700
        : Colors.orange.shade800;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isFarmer ? "Farmer Registration" : "Customer Registration",
        ),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Dynamic Icon
              CircleAvatar(
                radius: 40,
                backgroundColor: themeColor.withOpacity(0.1),
                child: Icon(
                  widget.isFarmer ? Icons.agriculture : Icons.person_add,
                  size: 50,
                  color: themeColor,
                ),
              ),
              const SizedBox(height: 30),

              // Full Name Field
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person_outline, color: themeColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email_outlined, color: themeColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Phone Number Field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Icon(Icons.phone_outlined, color: themeColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password (min. 6 characters)",
                  prefixIcon: Icon(Icons.lock_outline, color: themeColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Create Account Button
              _isLoading
                  ? CircularProgressIndicator(color: themeColor)
                  : ElevatedButton(
                      onPressed: _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

              const SizedBox(height: 20),

              // Back to Login Link
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Already have an account? Login",
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
