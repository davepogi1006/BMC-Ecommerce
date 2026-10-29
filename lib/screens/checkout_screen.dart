import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/cart_item.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../utils/format.dart';
import '../widgets/tech_ui.dart';
import 'main_shell.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final CartItem? directItem;
  final List<CartItem>? checkoutItems;

  const CheckoutScreen({
    super.key,
    this.directItem,
    this.checkoutItems,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  late final List<CartItem> _items;
  bool _busy = false;
  bool _orderSaved = false;
  String? _orderId;
  int? _orderNumber;

  double get _total =>
      _items.fold<double>(0, (sum, item) => sum + item.subtotal);

  @override
  void initState() {
    super.initState();
    final initialItems = widget.directItem == null
        ? widget.checkoutItems ?? context.read<CartProvider>().items
        : [widget.directItem!];
    _items = initialItems
        .map((item) => CartItem(
              product: item.product,
              quantity: item.quantity,
            ))
        .toList();
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_orderId == null && !_formKey.currentState!.validate()) return;
    if (_items.isEmpty) return;

    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before checking out.')),
      );
      return;
    }

    final orderService = OrderService();
    setState(() {
      _busy = true;
      _orderId ??= orderService.newOrderId();
      _orderNumber ??= orderService.newOrderNumber();
    });

    try {
      if (!_orderSaved) {
        await orderService.createOrder(
          orderId: _orderId!,
          userId: uid,
          items: _items,
          total: _total,
          address: _address.text.trim(),
          phone: _phone.text.trim(),
          orderNumber: _orderNumber!,
        );
        if (!mounted) return;
        _orderSaved = true;

        if (widget.directItem == null && widget.checkoutItems != null) {
          context.read<CartProvider>().removeItems(
                _items.map((item) => item.product.id),
              );
        }
      }

      final paymentUrl =
          await PaymentService().createPaymentUrl(_orderId!);
      if (!mounted) return;
      setState(() => _busy = false);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentScreen(paymentUrl: paymentUrl),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start payment: $e')),
      );
    }
  }

  void _backToMainPage() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    mainShellKey.currentState?.selectShop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        actions: [
          TextButton.icon(
            onPressed: _backToMainPage,
            icon: const Icon(Icons.home_outlined),
            label: const Text('Exit to home'),
          ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('There are no items to check out.'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const TechPageIntro(
                        eyebrow: 'Secure checkout',
                        title: 'Delivery details.',
                        description:
                            'Confirm the destination and continue to payment. Your order stays pending until payment is confirmed.',
                      ),
                      Text(
                        'ORDER SUMMARY',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      for (final item in _items)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title:
                              Text('${item.product.name}  x${item.quantity}'),
                          trailing: Text(
                            peso(item.subtotal),
                            style: TextStyle(
                              color: AppTheme.priceColor(
                                  Theme.of(context).brightness),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            peso(_total),
                            style: TextStyle(
                              color: AppTheme.priceColor(
                                  Theme.of(context).brightness),
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const TechEyebrow(
                        'Delivery destination',
                        icon: Icons.local_shipping_outlined,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _address,
                        maxLines: 2,
                        enabled: _orderId == null,
                        decoration: const InputDecoration(
                          labelText: 'Shipping address',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().length < 8)
                                ? 'Enter your address'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        enabled: _orderId == null,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().length < 7)
                                ? 'Enter your phone'
                                : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy ? null : _placeOrder,
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _orderSaved
                                    ? 'Retry payment'
                                    : _orderId == null
                                        ? 'Place order & pay'
                                        : 'Retry checkout',
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
