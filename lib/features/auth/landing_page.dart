import 'package:flutter/material.dart';
import 'role_selection.dart'; // Make sure you have this file created

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We use a Stack to put a background color or image if you like
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade800, Colors.green.shade400],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            const Icon(
              Icons.agriculture_rounded,
              size: 120,
              color: Colors.white,
            ),
            const SizedBox(height: 20),

            // App Name
            const Text(
              "AgroConnect",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),

            // Tagline
            const Text(
              "Direct from Farm to Table",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 80),

            // Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade800,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                onPressed: () {
                  // Navigate to the Role Selection Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoleSelectionPage(),
                    ),
                  );
                },
                child: const Text(
                  "Get Started",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
