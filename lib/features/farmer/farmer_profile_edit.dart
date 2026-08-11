import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FarmerProfileEdit extends StatefulWidget {
  const FarmerProfileEdit({super.key});

  @override
  State<FarmerProfileEdit> createState() => _FarmerProfileEditState();
}

class _FarmerProfileEditState extends State<FarmerProfileEdit> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  // Load existing data into the text fields
  void _loadCurrentData() async {
    var doc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(uid)
        .get();
    if (doc.exists) {
      setState(() {
        _nameController.text = doc['name'] ?? "";
        _phoneController.text = doc['phone'] ?? "";
      });
    }
  }

  // The Update Logic you asked for
  void _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('farmers').doc(uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Farm/Farmer Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _updateProfile,
                    child: const Text("Save Changes"),
                  ),
          ],
        ),
      ),
    );
  }
}
