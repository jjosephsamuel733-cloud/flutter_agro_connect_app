import 'dart:convert'; // Added for base64Decode
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageInventory extends StatelessWidget {
  const ManageInventory({super.key});

  // Toggle Out of Stock Logic
  void _toggleStock(String productId, bool currentlyInStock) {
    FirebaseFirestore.instance.collection('products').doc(productId).update({
      'is_out_of_stock': currentlyInStock,
    });
  }

  // Delete Product Logic
  void _deleteProduct(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product?"),
        content: const Text("Are you sure you want to remove this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('products')
                  .doc(productId)
                  .delete();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not Logged In")));
    }

    final String uid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Products"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('farmerUid', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(
              child: Text("You haven't added any products yet."),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              var p = products[index];
              var data = p.data() as Map<String, dynamic>;

              bool isOutOfStock = data.containsKey('is_out_of_stock')
                  ? data['is_out_of_stock']
                  : false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    // --- FIXED: Using Image.memory instead of Image.network ---
                    child: data['imageData'] != null
                        ? Image.memory(
                            base64Decode(data['imageData']),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image),
                          )
                        : const Icon(Icons.image_not_supported),
                  ),
                  title: Text(
                    data['name'] ?? "Unnamed Product",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Price: ₹${data['price']} | Stock: ${data['stocks_in_hand']}kg",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: isOutOfStock
                            ? "Mark as In Stock"
                            : "Mark Out of Stock",
                        icon: Icon(
                          isOutOfStock
                              ? Icons.do_not_disturb_on
                              : Icons.check_circle,
                          color: isOutOfStock ? Colors.red : Colors.green,
                        ),
                        onPressed: () => _toggleStock(p.id, !isOutOfStock),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.grey,
                        ),
                        onPressed: () => _deleteProduct(context, p.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
