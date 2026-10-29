import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app_theme.dart';
import '../models/product.dart';
import '../utils/format.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(url: product.imageUrl),
                  if (product.tags.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 140),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Text(
                          product.tags.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  if (product.isFeatured)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Text(
                          'FEATURED',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      peso(product.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.priceColor(colors.brightness),
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          product.inStock
                              ? Icons.check_circle
                              : Icons.remove_circle,
                          size: 12,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.inStock ? 'In stock' : 'Out of stock',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Network image with a placeholder icon when there is no picture.
class ProductImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  const ProductImage({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.hardware, size: 48, color: colors.onSurfaceVariant),
      ),
    );
    if (url.isEmpty) return placeholder;
    return LayoutBuilder(
      builder: (context, constraints) {
        final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        final width = constraints.maxWidth.isFinite
            ? (constraints.maxWidth * devicePixelRatio).round().clamp(1, 1200)
            : null;
        return CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          memCacheWidth: width,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (_, __) => placeholder,
          errorWidget: (_, __, ___) => placeholder,
        );
      },
    );
  }
}
