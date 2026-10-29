import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

/// Product reads/writes. (Orders are in order_service.dart, Phase 4.)
class FirestoreService {
  final _products = FirebaseFirestore.instance.collection('products');

  /// Live list: updates instantly when an admin adds a product.
  /// We filter by category in the app (not in the query) so you don't
  /// need to create a Firestore index.
  Stream<List<Product>> streamProducts() {
    return _products
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Product.fromDoc).toList());
  }

  Future<void> addProduct(Product p) {
    return _products.add({
      ...p.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProduct(Product product) {
    return _products.doc(product.id).update({
      ...product.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String productId) {
    return _products.doc(productId).delete();
  }
}
