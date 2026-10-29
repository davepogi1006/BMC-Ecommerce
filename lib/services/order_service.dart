import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class OrderService {
  final _orders = FirebaseFirestore.instance.collection('orders');

  /// Generates an ID that can be reused if the first save has an uncertain result.
  String newOrderId() => _orders.doc().id;

  int newOrderNumber() => DateTime.now().millisecondsSinceEpoch;

  /// Saves a pending order once and returns its id.
  /// The status can only be changed to "paid"/"failed" by the Supabase
  /// webhook (Phase 5), never by the app.
  Future<String> createOrder({
    required String orderId,
    required String userId,
    required List<CartItem> items,
    required double total,
    required String address,
    required String phone,
    required int orderNumber,
  }) async {
    final ref = _orders.doc(orderId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) {
        if (existing.data()?['userId'] != userId) {
          throw StateError('This order could not be resumed.');
        }
        return;
      }

      transaction.set(ref, {
        'userId': userId,
        'orderNumber': orderNumber,
        'items': items.map((i) => i.toMap()).toList(),
        'totalAmount': total,
        'status': 'pending',
        'shippingAddress': address,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    return ref.id;
  }

  /// Live list of one user's orders, newest first.
  /// Sorted in the app so no Firestore index is needed.
  Stream<List<OrderModel>> streamMyOrders(String userId) {
    return _orders.where('userId', isEqualTo: userId).snapshots().map((snap) {
      final list = snap.docs.map(OrderModel.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
