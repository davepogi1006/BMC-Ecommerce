import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../utils/format.dart';
import '../widgets/product_card.dart';
import '../widgets/tech_ui.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _selectedIds = {};
  final Set<String> _knownIds = {};

  void _syncSelection(Iterable<CartItem> items) {
    final currentIds = items.map((item) => item.product.id).toSet();
    _selectedIds.removeWhere((id) => !currentIds.contains(id));
    _selectedIds.addAll(currentIds.difference(_knownIds));
    _knownIds
      ..clear()
      ..addAll(currentIds);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final colors = Theme.of(context).colorScheme;
    final items = cart.items;
    _syncSelection(items);
    final selectedItems = items
        .where((item) => _selectedIds.contains(item.product.id))
        .toList();
    final selectedTotal =
        selectedItems.fold<double>(0, (total, item) => total + item.subtotal);
    final allSelected = items.isNotEmpty && selectedItems.length == items.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cart.isEmpty
          ? const Center(
              child: TechPageIntro(
                eyebrow: 'Your selection',
                title: 'Cart is empty.',
                description:
                    'Add gear from the shop and it will be ready here.',
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      const TechEyebrow('Your selection'),
                      const SizedBox(height: 8),
                      Text(
                        '${cart.count} ${cart.count == 1 ? 'ITEM' : 'ITEMS'}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Checkbox(
                            value: allSelected,
                            onChanged: (selected) => setState(() {
                              if (selected == true) {
                                _selectedIds.addAll(
                                  items.map((item) => item.product.id),
                                );
                              } else {
                                _selectedIds.clear();
                              }
                            }),
                          ),
                          const Text('Select all'),
                          const Spacer(),
                          Text('${selectedItems.length} selected'),
                        ],
                      ),
                      for (final item in items) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: constraints.maxWidth >= 560
                                ? Row(
                                    children: [
                                      _ItemSelectionCheckbox(
                                        selected: _selectedIds
                                            .contains(item.product.id),
                                        onChanged: (selected) =>
                                            _toggleItem(item, selected),
                                      ),
                                      _ProductThumbnail(
                                          url: item.product.imageUrl),
                                      const SizedBox(width: 14),
                                      Expanded(
                                          child: _ItemDescription(item: item)),
                                      _QuantityControls(item: item),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          _ItemSelectionCheckbox(
                                            selected: _selectedIds
                                                .contains(item.product.id),
                                            onChanged: (selected) =>
                                                _toggleItem(item, selected),
                                          ),
                                          _ProductThumbnail(
                                              url: item.product.imageUrl),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _ItemDescription(item: item),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 22),
                                      _QuantityControls(item: item),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.outlineVariant)),
                ),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: LayoutBuilder(
                      builder: (context, footerConstraints) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('SELECTED TOTAL',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall),
                                  const SizedBox(height: 3),
                                  Text(
                                    peso(selectedTotal),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppTheme.priceColor(
                                              colors.brightness),
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: selectedItems.isEmpty
                                  ? null
                                  : () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CheckoutScreen(
                                            checkoutItems:
                                                List.of(selectedItems),
                                          ),
                                        ),
                                      ),
                              icon: const Icon(Icons.arrow_forward, size: 18),
                              label: Text(footerConstraints.maxWidth < 440
                                  ? 'Checkout'
                                  : 'Continue to checkout'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  void _toggleItem(CartItem item, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedIds.add(item.product.id);
      } else {
        _selectedIds.remove(item.product.id);
      }
    });
  }
}

class _ItemSelectionCheckbox extends StatelessWidget {
  final bool selected;
  final ValueChanged<bool?> onChanged;

  const _ItemSelectionCheckbox({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Checkbox(
        value: selected,
        onChanged: onChanged,
      );
}

class _ProductThumbnail extends StatelessWidget {
  final String url;

  const _ProductThumbnail({required this.url});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 76,
        height: 76,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: ProductImage(url: url),
        ),
      );
}

class _ItemDescription extends StatelessWidget {
  final CartItem item;

  const _ItemDescription({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          '${peso(item.product.price)}  ×  ${item.quantity}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.priceColor(colors.brightness),
                fontFamily: 'monospace',
              ),
        ),
      ],
    );
  }
}

class _QuantityControls extends StatelessWidget {
  final CartItem item;

  const _QuantityControls({required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CartProvider>();
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Decrease quantity',
          onPressed: () => provider.setQuantity(
            item.product.id,
            item.quantity - 1,
          ),
          icon: const Icon(Icons.remove),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 36),
          alignment: Alignment.center,
          child: Text('${item.quantity}',
              style: Theme.of(context).textTheme.titleSmall),
        ),
        IconButton(
          tooltip: 'Increase quantity',
          onPressed: () => provider.setQuantity(
            item.product.id,
            item.quantity + 1,
          ),
          icon: const Icon(Icons.add),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Remove item',
          color: colors.onSurfaceVariant,
          onPressed: () => provider.remove(item.product.id),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}
