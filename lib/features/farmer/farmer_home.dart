import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'add_product_page.dart';
import 'manage_inventory.dart';
import 'farmer_orders.dart';
import "ai_insights_page.dart";

class FarmerHome extends StatefulWidget {
  const FarmerHome({super.key});

  @override
  State<FarmerHome> createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  late AnimationController _controller;
  String farmerName = "Farmer";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
    _loadFarmerName();
  }

  // Fetches the name from your 'farmers' collection
  Future<void> _loadFarmerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          farmerName = doc['name'] ?? "Farmer";
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Welcome Banner ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, $farmerName!",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Tiruchirappalli Region",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // --- Animated Grid ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _animatedMenuCard(
                    index: 0,
                    title: "Add Product",
                    icon: Icons.add_shopping_cart,
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const AddProductPage()),
                    ),
                  ),
                  _animatedMenuCard(
                    index: 1,
                    title: "My Inventory",
                    icon: Icons.inventory_2,
                    color: Colors.brown,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const ManageInventory(),
                      ),
                    ),
                  ),
                  _animatedMenuCard(
                    index: 2,
                    title: "Orders",
                    icon: Icons.receipt_long,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const FarmerOrders()),
                    ),
                  ),
                  _animatedMenuCard(
                    index: 3,
                    title: "AI Insights",
                    icon: Icons.psychology,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const AIInsightsPage()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedMenuCard({
    required int index,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval((0.1 * index), 1.0, curve: Curves.easeOutBack),
    );

    return ScaleTransition(
      scale: animation,
      child: FadeTransition(
        opacity: animation,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, size: 35, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Feature under development for Tiruchirappalli region."),
      ),
    );
  }
}
