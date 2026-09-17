import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch all products
  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product(
              id: doc.id,
              name: doc['name'],
              price: doc['price'].toDouble(),
              imageUrl: doc['imageUrl'],
              rating: doc['rating'],
            )).toList());
  }

  // Fetch products by category, brand, or price range
  Future<List<Product>> getFilteredProducts({
    String? category,
    String? brand,
    double? minPrice,
    double? maxPrice,
  }) async {
    Query query = _db.collection('products');

    if (category != null) query = query.where('category', isEqualTo: category);
    if (brand != null) query = query.where('brand', isEqualTo: brand);
    if (minPrice != null) query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    if (maxPrice != null) query = query.where('price', isLessThanOrEqualTo: maxPrice);

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => Product(
              id: doc.id,
              name: doc['name'],
              price: doc['price'].toDouble(),
              imageUrl: doc['imageUrl'],
              rating: doc['rating'],
            ))
        .toList();
  }
}
