import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../utils/format.dart';
import '../widgets/tech_ui.dart';
import 'payment_screen.dart';

/// Phase 5 version: live status chip + "Pay now" for pending orders.
class OrdersScreen extends StatefulWidget {
  final Stream<List<OrderModel>>? ordersStream;

  const OrdersScreen({
    super.key,
    this.ordersStream,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final Stream<List<OrderModel>> _stream;

  @override
  void initState() {
    super.initState();
    final ordersStream = widget.ordersStream;
    if (ordersStream != null) {
      _stream = ordersStream;
    } else {
      final uid = context.read<AuthProvider>().user!.uid;
      _stream = OrderService().streamMyOrders(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: StreamBuilder<List<OrderModel>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TechEyebrow('Connection issue',
                        icon: Icons.error_outline),
                    const SizedBox(height: 10),
                    Text('Orders could not be loaded.\n${snap.error}',
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snap.data!;
          if (orders.isEmpty) {
            return const Center(
              child: TechPageIntro(
                eyebrow: 'Order history',
                title: 'Nothing ordered yet.',
                description:
                    'Completed and pending checkouts will appear here.',
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            itemCount: orders.length,
            itemBuilder: (_, i) => _OrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _paying = false;

  Future<void> _payNow() async {
    setState(() => _paying = true);
    try {
      final paymentUrl =
          await PaymentService().createPaymentUrl(widget.order.id);
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentScreen(paymentUrl: paymentUrl),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed to start: $e')));
      }
    }
    if (mounted) setState(() => _paying = false);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Order #${order.orderNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                TechStatusLabel(status: order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                DateFormat('MMM d, y  h:mm a')
                    .format(order.createdAt)
                    .toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontFamily: 'monospace',
                )),
            const SizedBox(height: 8),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item['name']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('×${item['quantity']}',
                        style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL', style: TextStyle(letterSpacing: 0.8)),
                Text(
                  peso(order.total),
                  style: TextStyle(
                    color: AppTheme.priceColor(Theme.of(context).brightness),
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (order.status == 'pending') ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _paying ? null : _payNow,
                child: _paying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Pay now'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return TechStatusLabel(status: status);
  }
}
