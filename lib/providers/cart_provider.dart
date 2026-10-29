import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

/// The shopping cart lives in memory (it resets when the app is closed).
class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  bool get isEmpty => _items.isEmpty;

  /// Total number of units, shown on the cart badge.
  int get count => _items.values.fold(0, (sum, i) => sum + i.quantity);

  double get total => _items.values.fold(0.0, (sum, i) => sum + i.subtotal);

  void add(Product product, {int qty = 1}) {
    final current = _items[product.id]?.quantity ?? 0;
    // Never allow more than the available stock.
    final newQty = (current + qty).clamp(1, product.stock);
    _items[product.id] = CartItem(product: product, quantity: newQty);
    notifyListeners();
  }

  void setQuantity(String productId, int qty) {
    final item = _items[productId];
    if (item == null) return;
    if (qty <= 0) {
      _items.remove(productId);
    } else {
      item.quantity = qty.clamp(1, item.product.stock);
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeItems(Iterable<String> productIds) {
    var changed = false;
    for (final productId in productIds) {
      changed = _items.remove(productId) != null || changed;
    }
    if (changed) notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}