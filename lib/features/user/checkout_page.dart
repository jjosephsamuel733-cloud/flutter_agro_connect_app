import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckoutPage extends StatelessWidget {
  final Map<String, dynamic> cartItem; // Simplified for one item for now
  final int quantity;
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  CheckoutPage({super.key, required this.cartItem, required this.quantity});

  void _processPayment(BuildContext context) async {
    // 1. Create Order in Firestore
    await FirebaseFirestore.instance.collection('orders').add({
      'farmerUid': cartItem['farmerUid'],
      'productName': cartItem['name'],
      'quantity': quantity,
      'totalAmount': cartItem['price'] * quantity,
      'customerAddress': _addressController.text,
      'customerPhone': _phoneController.text,
      'status': 'received', // Initial status
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Show Success and Notify (Farmer side will see this in 'Active Orders')
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Payment Successful"),
        content: const Text(
          "The farmer has been notified and your order is being processed.",
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double total = cartItem['price'] * quantity;

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Delivery Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Full Address"),
              ),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
              ),
              const Divider(height: 40),

              const Text(
                "Receipt",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ListTile(
                title: Text(cartItem['name']),
                subtitle: Text("Qty: $quantity"),
                trailing: Text("₹${cartItem['price'] * quantity}"),
              ),
              const ListTile(
                title: Text("Delivery Charges"),
                trailing: Text("₹0.00"), // Free for now
              ),
              const Divider(),
              ListTile(
                title: const Text(
                  "Total Amount",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  "₹$total",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () => _processPayment(context),
                child: const Text("Pay Now (Test Mode)"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
