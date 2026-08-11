import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'cart_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> productData;
  const ProductDetailsPage({super.key, required this.productData});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _quantity = 1;
  bool _isAdding = false;

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isAdding = true);

    try {
      await FirebaseFirestore.instance.collection('carts').add({
        'userUid': user.uid,
        'productId': widget.productData['id'],
        'productName': widget.productData['name'],
        'price': widget.productData['price'],
        'quantity': _quantity,
        'totalPrice': widget.productData['price'] * _quantity,
        'imageData': widget.productData['imageData'],
        'farmerId': widget.productData['farmer_id'],
        'timestamp': FieldValue.serverTimestamp(),
      });
      _showCartSuccessDialog();
    } catch (e) {
      debugPrint("Cart Error: $e");
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _showCartSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 50),
            SizedBox(height: 10),
            Text("Added to Cart"),
          ],
        ),
        content: Text(
          "You have added $_quantity kg of ${widget.productData['name']}.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Continue"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const CartPage()),
              );
            },
            child: const Text(
              "Go to Cart",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.productData;
    final themeColor = Colors.green.shade700;

    return Scaffold(
      // Standard AppBar ensures image doesn't go to the very top
      appBar: AppBar(
        title: const Text("Crop Details"),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: AnimationLimiter(
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 600),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 30.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                // 1. IMAGE CONTAINER (Fixed size, No text inside)
                Hero(
                  tag: data['id'] ?? data['name'],
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: data['imageData'] != null
                          ? Image.memory(
                              base64Decode(data['imageData']),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 80),
                            ),
                    ),
                  ),
                ),

                // 2. PRODUCT INFO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['name'] ?? "Product",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "₹${data['price']}/kg",
                            style: TextStyle(
                              fontSize: 22,
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Directly from local farmer",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const Divider(height: 40),

                      const Text(
                        "Select Quantity",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quantity Selector
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildQtyBtn(Icons.remove, () {
                                if (_quantity > 1) setState(() => _quantity--);
                              }),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 25,
                                ),
                                child: Text(
                                  "$_quantity kg",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildQtyBtn(
                                Icons.add,
                                () => setState(() => _quantity++),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Price Summary Box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Estimate:",
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              "₹${(data['price'] * _quantity).toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100), // Space for bottom button
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isAdding
            ? const Center(heightFactor: 1, child: CircularProgressIndicator())
            : ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                label: const Text(
                  "Add to Cart",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                ),
              ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.green.shade700),
      padding: const EdgeInsets.all(12),
    );
  }
}
