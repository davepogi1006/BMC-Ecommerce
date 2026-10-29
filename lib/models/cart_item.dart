import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;

  /// Saved inside the order document at checkout.
  Map<String, dynamic> toMap() => {
        'productId': product.id,
        'name': product.name,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'quantity': quantity,
      };
}
