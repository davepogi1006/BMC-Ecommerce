import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../utils/format.dart';
import '../widgets/product_card.dart';
import '../widgets/tech_ui.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final image = _productImage(product, compact: !wide);
          final details = _productDetails(product);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.fromLTRB(wide ? 24 : 0, 0, wide ? 24 : 0, 24),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: image),
                          const SizedBox(width: 28),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: details,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                            child: _productDetails(
                              product,
                              summaryOnly: true,
                            ),
                          ),
                          image,
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                            child: _productDetails(
                              product,
                              factsOnly: true,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              letterSpacing: 0.8,
                            ),
                      ),
                      Text(
                        peso(product.price * _quantity),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.priceColor(colors.brightness),
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.bolt),
                          label: const Text('Buy now'),
                          onPressed: product.inStock
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CheckoutScreen(
                                        directItem: CartItem(
                                          product: product,
                                          quantity: _quantity,
                                        ),
                                      ),
                                    ),
                                  )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add to cart'),
                          onPressed: product.inStock
                              ? () {
                                  context
                                      .read<CartProvider>()
                                      .add(product, qty: _quantity);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${product.name} added to cart ($_quantity).'),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _productImage(Product product, {required bool compact}) {
    final colors = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: compact ? 1.35 : 1.15,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ProductImage(url: product.imageUrl),
          Positioned(
            left: 16,
            top: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text(
                  product.category,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
          if (product.isFeatured)
            Positioned(
              right: 16,
              top: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  child: Text(
                    'FEATURED',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _productDetails(
    Product product, {
    bool summaryOnly = false,
    bool factsOnly = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!factsOnly) ...[
          TechEyebrow('Product / ${product.category}'),
          const SizedBox(height: 10),
          Text(
            product.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      peso(product.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.priceColor(colors.brightness),
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                  ),
                  if (product.isFeatured)
                    Icon(Icons.star_rounded, color: colors.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              border: Border(
                left: BorderSide(color: colors.primary, width: 3),
                top: BorderSide(color: colors.outlineVariant),
                right: BorderSide(color: colors.outlineVariant),
                bottom: BorderSide(color: colors.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRODUCT DESCRIPTION',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description.trim().isEmpty
                      ? 'No description has been provided for this product.'
                      : product.description.trim(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
        if (!summaryOnly) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                product.inStock
                    ? Icons.check_circle_outline
                    : Icons.block_outlined,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Text(
                product.inStock
                    ? '${product.stock} available'
                    : 'Currently out of stock',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          if (product.tags.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Product labels',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: product.tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
          if (product.inStock) ...[
            const SizedBox(height: 24),
            Text(
              'Quantity',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _QuantityButton(
                  icon: Icons.remove,
                  onPressed:
                      _quantity > 1 ? () => setState(() => _quantity--) : null,
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add,
                  onPressed: _quantity < product.stock
                      ? () => setState(() => _quantity++)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Maximum ${product.stock} per order',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: icon == Icons.add ? 'Increase quantity' : 'Decrease quantity',
    );
  }
}
