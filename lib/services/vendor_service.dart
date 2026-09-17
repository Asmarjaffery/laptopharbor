// lib/services/vendor_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class VendorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a vendor
  Future<void> addVendor(UserModel vendor) async {  // ✓ User → UserModel
    await _db.collection('users').doc(vendor.id).set({
      'name': vendor.name,
      'email': vendor.email,
      'phone': vendor.phone,
      'role': 'vendor',
      'profileImage': vendor.profileImage ?? '',  // ✓ imageUrl → profileImage
    });
  }

  // Get all vendors
  Stream<List<UserModel>> getVendors() {  // ✓ User → UserModel
    return _db
        .collection('users')
        .where('role', isEqualTo: 'vendor')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return UserModel(  // ✓ User → UserModel
                id: doc.id,
                name: data['name'] ?? '',
                email: data['email'] ?? '',
                phone: data['phone'] ?? '',
                role: data['role'] ?? 'vendor',
                profileImage: data['profileImage'],  // ✓ imageUrl → profileImage
              );
            })
            .toList());
  }
}