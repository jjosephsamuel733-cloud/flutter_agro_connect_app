import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'farmer_store_page.dart'; // Create this to show the farmer's items

class DirectSearchView extends StatefulWidget {
  const DirectSearchView({super.key});

  @override
  State<DirectSearchView> createState() => _DirectSearchViewState();
}

class _DirectSearchViewState extends State<DirectSearchView> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  void _findFarmer() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() => _isSearching = true);

    try {
      // FIXED: Using isEqualTo instead of '=='
      var result = await FirebaseFirestore.instance
          .collection('farmers')
          .where('farmer_id', isEqualTo: _searchController.text.trim())
          .get();

      if (result.docs.isNotEmpty) {
        var farmerData = result.docs.first.data();

        if (mounted) {
          // Navigate to the specific farmer's store
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FarmerStorePage(
                farmerUid: farmerData['uid'],
                farmerName: farmerData['name'],
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No farmer found with this ID")),
          );
        }
      }
    } catch (e) {
      debugPrint("Search Error: $e");
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Text(
            "Connect Directly to a Farm",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: "Enter 5-digit Farmer ID",
              prefixIcon: Icon(Icons.pin_drop),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: _isSearching ? null : _findFarmer,
            child: _isSearching
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Go to Farm"),
          ),
        ],
      ),
    );
  }
}
