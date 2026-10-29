import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final int orderNumber;
  final String status; // pending | paid | failed
  final double total;
  final String address;
  final DateTime createdAt;
  final List<Map<String, dynamic>> items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.address,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final createdAt =
        (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return OrderModel(
      id: doc.id,
      orderNumber:
          (d['orderNumber'] as num?)?.toInt() ?? createdAt.millisecondsSinceEpoch,
      status: d['status'] ?? 'pending',
      total: (d['totalAmount'] ?? 0).toDouble(),
      address: d['shippingAddress'] ?? '',
      // createdAt is briefly null right after saving (server timestamp)
      createdAt: createdAt,
      items: List<Map<String, dynamic>>.from(d['items'] ?? []),
    );
  }
}