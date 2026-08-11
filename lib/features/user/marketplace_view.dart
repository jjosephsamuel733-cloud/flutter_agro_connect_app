import 'dart:convert'; // Required for base64Decode
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_details_page.dart';

class MarketplaceView extends StatelessWidget {
  const MarketplaceView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Only show items that are NOT out of stock and sort by price
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('is_out_of_stock', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!.docs;

        if (products.isEmpty) {
          return const Center(child: Text("No products available right now."));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72, // Adjusted for text and buttons
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            var p = products[index].data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                // Navigate to the corrected ProductDetailsPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsPage(productData: p),
                  ),
                );
              },
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- FIXED: Base64 Image Decoding ---
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: p['imageData'] != null
                            ? Image.memory(
                                base64Decode(p['imageData']),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 50),
                              )
                            : const Icon(Icons.image_not_supported, size: 50),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['name'] ?? "Product",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₹${p['price']}/kg",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Stock: ${p['stocks_in_hand']}kg",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              // Small ID tag for transparency
                              Text(
                                "ID: ${p['farmer_id'] ?? 'N/A'}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
