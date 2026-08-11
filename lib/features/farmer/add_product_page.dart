import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/ai_helper.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  CameraController? _controller;
  XFile? _imageFile;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  String _category = "Vegetables"; // Default category
  bool _isUploading = false;
  bool _isAnalyzing = false;

  final List<String> _categories = [
    "Vegetables",
    "Fruits",
    "Grains",
    "Pulses",
    "Dairy",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _captureAndCategorize() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      setState(() {
        _imageFile = image;
        _isAnalyzing = true;
      });

      // AI Analysis
      String detected = await AIHelper.getCategoryFromImage(image.path);

      setState(() {
        // Simple logic to match AI string to our dropdown
        _category = _matchCategory(detected);
        _isAnalyzing = false;
      });
    } catch (e) {
      debugPrint("AI Error: $e");
      setState(() => _isAnalyzing = false);
    }
  }

  String _matchCategory(String input) {
    for (var cat in _categories) {
      if (input.toLowerCase().contains(cat.toLowerCase())) return cat;
    }
    return "Other";
  }

  Future<void> _saveProduct() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _imageFile == null || _nameController.text.isEmpty) {
      _showSnackBar("Please complete all fields and capture an image.");
      return;
    }

    setState(() => _isUploading = true);

    try {
      DocumentSnapshot farmerSnap = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .get();
      String farmerId =
          (farmerSnap.data() as Map<String, dynamic>)['farmer_id'] ?? "00000";

      final bytes = await _imageFile!.readAsBytes();
      String base64Image = base64Encode(bytes);

      DocumentReference ref = FirebaseFirestore.instance
          .collection('products')
          .doc();
      await ref.set({
        'id': ref.id,
        'farmerUid': user.uid,
        'farmer_id': farmerId,
        'name': _nameController.text.trim(),
        'category': _category,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'stocks_in_hand': int.tryParse(_stockController.text) ?? 0,
        'imageData': base64Image,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnackBar("Product Listed!", isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar("Save Error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Product"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- CAMERA VIEW / IMAGE PREVIEW ---
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.black,
              child: _imageFile == null
                  ? (_controller != null && _controller!.value.isInitialized
                        ? CameraPreview(_controller!)
                        : const Center(child: CircularProgressIndicator()))
                  : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
            ),

            // --- CAMERA ACTIONS ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: _imageFile == null
                  ? ElevatedButton.icon(
                      onPressed: _captureAndCategorize,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Capture & Analyze"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () => setState(() => _imageFile = null),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retake Photo"),
                    ),
            ),

            // --- FORM FIELDS ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  if (_isAnalyzing)
                    const LinearProgressIndicator(color: Colors.green)
                  else
                    _buildDropdown(),

                  const SizedBox(height: 15),
                  _buildTextField(_nameController, "Product Name", Icons.eco),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _priceController,
                          "Price (₹)",
                          Icons.currency_rupee,
                          isNum: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          _stockController,
                          "Stock (kg)",
                          Icons.inventory,
                          isNum: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  _isUploading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _saveProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "List Product",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          isExpanded: true,
          items: _categories.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text("Category: $val"),
            );
          }).toList(),
          onChanged: (newVal) => setState(() => _category = newVal!),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNum = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
