import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart'; // Make sure this exists for farmers

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Join AgroConnect"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.agriculture_rounded,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              "Choose your role to continue",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),

            // Farmer Section
            _buildRoleButton(
              context,
              title: "I am a Farmer",
              subtitle: "Sell products & manage orders",
              icon: Icons.grass,
              color: Colors.green.shade700,
              onPressed: () {
                // For farmers, usually you want to offer Signup first or a direct Login
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => const LoginPage(isFarmer: true),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // User Section
            _buildRoleButton(
              context,
              title: "I am a Customer",
              subtitle: "Browse fresh products & buy",
              icon: Icons.shopping_basket,
              color: Colors.orange.shade800,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => const LoginPage(isFarmer: false),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 100,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(icon, size: 40),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
