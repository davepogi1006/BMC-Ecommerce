import 'package:cloud_firestore/cloud_firestore.dart';

/// Categories used by the filter chips and the admin form.
const productCategories = [
  'Power Tools',
  'Hand Tools',
  'CPU',
  'GPU',
  'Motherboards',
  'RAM',
  'Power Supply',
  'Monitors',
  'Peripherals',
];

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final int stock;
  final List<String> tags;
  final bool isFeatured;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.stock,
    this.tags = const [],
    this.isFeatured = false,
  });

  bool get inStock => stock > 0;

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Product(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      category: d['category'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      stock: (d['stock'] ?? 0).toInt(),
      tags: (d['tags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      isFeatured: d['isFeatured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
        'stock': stock,
        'tags': tags,
        'isFeatured': isFeatured,
      };
}
