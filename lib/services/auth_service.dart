import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

// Ensure these paths match your actual file locations
import '../features/farmer/farmer_home.dart';
import '../features/user/user_home.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Unified Sign Up (Handles both Farmers and Users) ---
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required bool isFarmer,
  }) async {
    try {
      // 1. Create the user account in Firebase Auth
      UserCredential res = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // 2. Determine which collection to save to
      String role = isFarmer ? 'farmer' : 'user';
      String collection = isFarmer ? 'farmers' : 'users';

      // 3. Prepare the data Map
      Map<String, dynamic> userData = {
        'uid': res.user!.uid,
        'name': name.trim(),
        'phone': phone.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 4. Add Farmer-specific 5-digit ID if they are a farmer
      if (isFarmer) {
        String fId = (10000 + Random().nextInt(90000)).toString();
        userData['farmer_id'] = fId;
      }

      // 5. Save the user profile to Firestore using their UID as the Document ID
      await _db.collection(collection).doc(res.user!.uid).set(userData);

      return res.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Error: ${e.code}");
      rethrow; // Pass to UI to show specific error message
    } catch (e) {
      debugPrint("General Sign Up Error: $e");
      rethrow;
    }
  }

  // --- Role-Based Login ---
  Future<void> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      // 1. Authenticate credentials
      UserCredential res = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // 2. Check the 'farmers' collection to see if this user is a farmer
      DocumentSnapshot farmerDoc = await _db
          .collection('farmers')
          .doc(res.user!.uid)
          .get();

      if (!context.mounted) return;

      // 3. Navigate based on existence in the farmer collection
      if (farmerDoc.exists) {
        debugPrint("User recognized as Farmer. Navigating to FarmerHome.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const FarmerHome()),
        );
      } else {
        debugPrint("User not found in 'farmers'. Navigating to UserHome.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const UserHome()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle common Firebase Login errors
      String errorMsg = "An error occurred. Please try again.";
      if (e.code == 'user-not-found')
        errorMsg = "No account exists for this email.";
      if (e.code == 'wrong-password') errorMsg = "Incorrect password.";
      if (e.code == 'invalid-credential')
        errorMsg = "Invalid email or password.";
      if (e.code == 'network-request-failed')
        errorMsg = "No internet connection.";

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.black,
          ),
        );
      }
    }
  }

  // --- Sign Out ---
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
