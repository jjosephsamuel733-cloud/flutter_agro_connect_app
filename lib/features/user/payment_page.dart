import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentPage extends StatefulWidget {
  final double totalAmount;
  final List<QueryDocumentSnapshot> cartItems;

  const PaymentPage({
    super.key,
    required this.totalAmount,
    required this.cartItems,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isProcessing = false;
  String _selectedMethod = "UPI"; // Default selection

  // Controllers for Customer Details
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Logic to process the transaction
  Future<void> _processOrder() async {
    // 1. Validation: Ensure fields aren't empty
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      _showErrorSnackBar("Please fill in all delivery details");
      return;
    }

    setState(() => _isProcessing = true);
    final user = FirebaseAuth.instance.currentUser;
    final WriteBatch batch = FirebaseFirestore.instance.batch();

    try {
      for (var item in widget.cartItems) {
        var data = item.data() as Map<String, dynamic>;
        DocumentReference orderRef = FirebaseFirestore.instance
            .collection('orders')
            .doc();

        // 2. Map data to the 'orders' collection
        batch.set(orderRef, {
          'customerId': user?.uid,
          'customerName': _nameController.text.trim(),
          'customerPhone': _phoneController.text.trim(),
          'location': _addressController.text.trim(),
          'farmerUid': data['farmerId'], // Links to custom business ID
          'productName': data['productName'],
          'quantity': data['quantity'],
          'totalPrice': data['totalPrice'],
          'status': 'received',
          'orderDate': FieldValue.serverTimestamp(),
          'paymentMethod': _selectedMethod,
        });

        // 3. Delete the item from the user's cart
        batch.delete(item.reference);
      }

      // Execute all operations (Atomic Transaction)
      await batch.commit();
      _showSuccess();
    } catch (e) {
      _showErrorSnackBar("Error processing order: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Show success dialog
  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Payment Successful!\nThe farmer has been notified of your order.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.of(
                  context,
                ).popUntil((route) => route.isFirst); // Go home
              },
              child: const Text(
                "Back to Market",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // Custom widget for selectable payment methods
  Widget _paymentTile(IconData icon, String title) {
    bool isSelected = _selectedMethod == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = title),
      child: Card(
        elevation: 0,
        color: isSelected ? Colors.green.shade50 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ListTile(
          leading: Icon(icon, color: isSelected ? Colors.green : Colors.grey),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.green.shade800 : Colors.black,
            ),
          ),
          trailing: Icon(
            isSelected ? Icons.check_circle : Icons.radio_button_off,
            color: isSelected ? Colors.green : Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shipping & Payment"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Delivery Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: "Delivery Address",
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
                hintText: "Street name, City, Pincode",
              ),
              maxLines: 2,
            ),

            const Divider(height: 40),
            const Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _paymentTile(Icons.account_balance_wallet, "UPI"),
            _paymentTile(Icons.payments, "Cash on Delivery"),

            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Grand Total:", style: TextStyle(fontSize: 16)),
                  Text(
                    "₹${widget.totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _isProcessing
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _processOrder,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Confirm & Place Order",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
