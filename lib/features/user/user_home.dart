import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../services/auth_service.dart';
import 'product_details_page.dart';
import 'cart_page.dart';
import 'my_orders_page.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final _auth = AuthService();
  final _searchController = TextEditingController();

  // State for filtering
  bool _isFarmerSearch = false;
  String _searchQuery = "";
  String _selectedCategory = "All";

  final List<String> _bannerImages = [
    'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1464226184884-fa280b87c399?auto=format&fit=crop&w=800&q=80',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.green.shade700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. MODERN APP BAR
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: themeColor,
            title: const Text(
              "AgroConnect",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const MyOrdersPage()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const CartPage()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await _auth.signOut();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: _buildSearchBar(themeColor),
            ),
          ),

          // 2. SLIDESHOW
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 160.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                ),
                items: _bannerImages.map((imageUrl) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 3. FUNCTIONAL QUICK CATEGORIES
          SliverToBoxAdapter(child: _buildSectionTitle("Quick Categories")),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _categoryIcon(Icons.grid_view_rounded, "All"),
                  _categoryIcon(Icons.grass, "Vegetables"),
                  _categoryIcon(Icons.apple, "Fruits"),
                  _categoryIcon(Icons.eco, "Grains"),
                  _categoryIcon(Icons.layers, "Pulses"),
                  _categoryIcon(Icons.egg, "Dairy"),
                ],
              ),
            ),
          ),

          // 4. PRODUCT GRID WITH DUAL FILTERING
          SliverToBoxAdapter(
            child: _buildSectionTitle(
              _isFarmerSearch
                  ? "Farmer Results"
                  : "Available in Tiruchirappalli",
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;

                // Category Filter
                bool catMatch =
                    _selectedCategory == "All" ||
                    (data['category'] ?? "") == _selectedCategory;

                // Search Filter
                bool searchMatch = true;
                if (_searchQuery.isNotEmpty) {
                  searchMatch = _isFarmerSearch
                      ? data['farmer_id'].toString().contains(_searchQuery)
                      : data['name'].toString().toLowerCase().contains(
                          _searchQuery,
                        );
                }
                return catMatch && searchMatch;
              }).toList();

              if (docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text("No products found in this category."),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      duration: const Duration(milliseconds: 500),
                      columnCount: 2,
                      child: ScaleAnimation(
                        child: FadeInAnimation(child: ProductCard(data: data)),
                      ),
                    );
                  }, childCount: docs.length),
                ),
              );
            },
          ),

          // 5. FOOTER
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
          SliverToBoxAdapter(child: _buildFooter()),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSearchBar(Color themeColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) =>
            setState(() => _searchQuery = val.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: _isFarmerSearch ? "Enter 5-digit ID..." : "Search crops...",
          prefixIcon: Icon(Icons.search, color: themeColor),
          suffixIcon: IconButton(
            icon: Icon(
              _isFarmerSearch ? Icons.person : Icons.agriculture,
              color: Colors.orange,
            ),
            onPressed: () => setState(() => _isFarmerSearch = !_isFarmerSearch),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _categoryIcon(IconData icon, String label) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: isSelected
                  ? Colors.green.shade700
                  : Colors.green.shade50,
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.green.shade700 : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: const Column(
        children: [
          Text(
            "AgroConnect",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Supporting local farmers in Tiruchirappalli.",
            style: TextStyle(color: Colors.white70),
          ),
          Divider(color: Colors.white24, height: 40),
          Text(
            "© 2026 AgroConnect. All rights reserved.",
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// SEPARATE PRODUCT CARD COMPONENT
class ProductCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const ProductCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsPage(productData: data),
        ),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: data['id'] ?? data['name'],
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: data['imageData'] != null
                      ? Image.memory(
                          base64Decode(data['imageData']),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "₹${data['price']}/kg",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Farmer ID: ${data['farmer_id']}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
