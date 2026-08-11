import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FarmerOrders extends StatelessWidget {
  const FarmerOrders({super.key});

  // Function to update the order status in Firestore
  void _updateStatus(
    BuildContext context,
    String orderId,
    String currentStatus,
  ) async {
    String nextStatus = 'received';
    if (currentStatus == 'received')
      nextStatus = 'transit';
    else if (currentStatus == 'transit')
      nextStatus = 'delivered';
    else
      return; // Already delivered

    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': nextStatus},
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Order moved to $nextStatus")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating status: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Sales Orders"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // 1. First, find the custom farmer_id (e.g. 15922) for this login UID
        future: FirebaseFirestore.instance
            .collection('farmers')
            .doc(authUser?.uid)
            .get(),
        builder: (context, farmerSnap) {
          if (farmerSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!farmerSnap.hasData || !farmerSnap.data!.exists) {
            return const Center(child: Text("Farmer profile not found."));
          }

          var farmerData = farmerSnap.data!.data() as Map<String, dynamic>;
          String customId = farmerData['farmer_id']?.toString() ?? "";

          return StreamBuilder<QuerySnapshot>(
            // 2. Now search orders where farmerUid == "15922"
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('farmerUid', isEqualTo: customId)
                .orderBy('orderDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory, size: 60, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text("No orders found for ID: $customId"),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  var orderId = docs[index].id;
                  String status = data['status'] ?? 'received';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(status),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        data['productName'] ?? "Product",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Customer: ${data['customerName']}"),
                      children: [
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow(
                                Icons.phone,
                                "Phone",
                                data['customerPhone'],
                              ),
                              _infoRow(
                                Icons.location_on,
                                "Address",
                                data['location'],
                              ),
                              _infoRow(
                                Icons.shopping_bag,
                                "Quantity",
                                "${data['quantity']} kg",
                              ),
                              _infoRow(
                                Icons.currency_rupee,
                                "Total Paid",
                                "₹${data['totalPrice']}",
                              ),
                              _infoRow(
                                Icons.info_outline,
                                "Status",
                                status.toUpperCase(),
                              ),
                              const SizedBox(height: 15),

                              // Button to update status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (status != 'delivered')
                                    ElevatedButton.icon(
                                      onPressed: () => _updateStatus(
                                        context,
                                        orderId,
                                        status,
                                      ),
                                      icon: Icon(
                                        status == 'received'
                                            ? Icons.local_shipping
                                            : Icons.check_circle,
                                      ),
                                      label: Text(
                                        status == 'received'
                                            ? "Mark as Shipped"
                                            : "Mark Delivered",
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        foregroundColor: Colors.white,
                                      ),
                                    )
                                  else
                                    const Text(
                                      "✅ Order Completed",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Helper function to color the icon based on status
  Color _getStatusColor(String status) {
    if (status == 'received') return Colors.orange;
    if (status == 'transit') return Colors.blue;
    if (status == 'delivered') return Colors.green;
    return Colors.grey;
  }

  // Helper widget for cleaner rows
  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? "Not provided")),
        ],
      ),
    );
  }
}
