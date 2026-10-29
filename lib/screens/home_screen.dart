import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import '../widgets/product_card.dart';
import '../widgets/tech_ui.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<Product>> _stream;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _category = 'All';
  String _searchQuery = '';
  String _sortOrder = 'newest';

  @override
  void initState() {
    super.initState();
    _stream = FirestoreService().streamProducts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _searchQuery = value.trim());
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    final chips = ['All', ...productCategories];

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = math.min(constraints.maxWidth, 1200.0);
          final sideInset = (constraints.maxWidth - contentWidth) / 2;
          final columns = contentWidth >= 900
              ? 3
              : contentWidth >= 600
                  ? 2
                  : 1;

          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        sideInset + 16, 14, sideInset + 16, 12),
                    child: const TechBrandLockup(showDescriptor: true),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        sideInset + 12, 0, sideInset + 12, 16),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search products, categories, or labels',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: _clearSearch,
                                icon: const Icon(Icons.clear),
                              ),
                      ),
                      onChanged: _updateSearch,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        sideInset + 16, 0, sideInset + 16, 6),
                    child: Text(
                      'Shop by category',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.fromLTRB(
                        sideInset + 12,
                        4,
                        sideInset + 12,
                        8,
                      ),
                      itemCount: chips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final selected = chips[i] == _category;
                        final colors = Theme.of(context).colorScheme;
                        return ChoiceChip(
                          label: Text(chips[i]),
                          selected: selected,
                          showCheckmark: false,
                          visualDensity: VisualDensity.standard,
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          labelStyle: TextStyle(
                            color:
                                selected ? colors.onPrimary : colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: colors.surfaceContainerLow,
                          selectedColor: colors.primary,
                          side: BorderSide(
                            color: selected
                                ? colors.primary
                                : colors.outlineVariant,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                          onSelected: (_) =>
                              setState(() => _category = chips[i]),
                        );
                      },
                    ),
                  ),
                ),
                StreamBuilder<List<Product>>(
                  stream: _stream,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text('Error: ${snap.error}')),
                      );
                    }
                    if (!snap.hasData) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final query = _searchQuery.toLowerCase();
                    final matchingProducts = snap.data!
                        .where((p) =>
                            _category == 'All' || p.category == _category)
                        .where((p) =>
                            query.isEmpty ||
                            p.name.toLowerCase().contains(query) ||
                            p.description.toLowerCase().contains(query) ||
                            p.category.toLowerCase().contains(query) ||
                            p.tags.any(
                                (tag) => tag.toLowerCase().contains(query)))
                        .toList();

                    final showHighlights =
                        _searchQuery.isEmpty && _category == 'All';
                    final featured = showHighlights
                        ? matchingProducts.where((p) => p.isFeatured).toList()
                        : <Product>[];
                    final products = matchingProducts
                        .where((p) => !showHighlights || !p.isFeatured)
                        .toList();
                    if (_sortOrder == 'priceLow') {
                      products.sort((a, b) => a.price.compareTo(b.price));
                    } else if (_sortOrder == 'priceHigh') {
                      products.sort((a, b) => b.price.compareTo(a.price));
                    }

                    final storefrontProducts = [...featured, ...products];
                    if (storefrontProducts.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 36,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  query.isEmpty
                                      ? 'No products here yet.'
                                      : 'No products match your search.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final bentoRows =
                        _buildBentoRows(storefrontProducts, columns);
                    return SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              sideInset + 16,
                              12,
                              sideInset + 16,
                              4,
                            ),
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? 'Search results'
                                  : _category == 'All'
                                      ? 'Shop the collection'
                                      : _category,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                sideInset + 16, 0, sideInset + 16, 8),
                            child: Row(
                              children: [
                                Text(
                                  '${storefrontProducts.length} ${storefrontProducts.length == 1 ? 'item' : 'items'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                                const Spacer(),
                                const Icon(Icons.sort, size: 18),
                                const SizedBox(width: 6),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _sortOrder,
                                    isDense: true,
                                    borderRadius: BorderRadius.circular(12),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'newest',
                                          child: Text('Newest')),
                                      DropdownMenuItem(
                                          value: 'priceLow',
                                          child: Text('Price: low to high')),
                                      DropdownMenuItem(
                                          value: 'priceHigh',
                                          child: Text('Price: high to low')),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _sortOrder = value);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            sideInset + 12,
                            4,
                            sideInset + 12,
                            20,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      index == bentoRows.length - 1 ? 0 : 12,
                                ),
                                child: _BentoProductRow(
                                  items: bentoRows[index],
                                  onTap: (product) =>
                                      Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(
                                        product: product,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              childCount: bentoRows.length,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<List<_BentoItem>> _buildBentoRows(
    List<Product> products,
    int columns,
  ) {
    final rows = <List<_BentoItem>>[];
    var index = 0;
    var pattern = 0;

    while (index < products.length) {
      final remaining = products.length - index;
      final next = products[index];

      if (columns == 1 || (columns == 2 && next.isFeatured)) {
        rows.add([_BentoItem(next, columns)]);
        index++;
      } else if (columns == 2) {
        final count = math.min(2, remaining);
        rows.add([
          for (var offset = 0; offset < count; offset++)
            _BentoItem(products[index + offset], 1),
        ]);
        index += count;
      } else if (next.isFeatured) {
        if (remaining == 1 || products[index + 1].isFeatured) {
          rows.add([_BentoItem(next, 3)]);
          index++;
        } else {
          rows.add([
            _BentoItem(next, 2),
            _BentoItem(products[index + 1], 1),
          ]);
          index += 2;
        }
      } else if (remaining > 1 && products[index + 1].isFeatured) {
        rows.add([
          _BentoItem(next, 1),
          _BentoItem(products[index + 1], 2),
        ]);
        index += 2;
      } else if (pattern % 3 == 2 && remaining >= 3) {
        rows.add([
          _BentoItem(next, 1),
          _BentoItem(products[index + 1], 1),
          _BentoItem(products[index + 2], 1),
        ]);
        index += 3;
        pattern++;
      } else {
        final count = math.min(2, remaining);
        rows.add([
          _BentoItem(next, pattern.isEven ? 2 : 1),
          if (count > 1)
            _BentoItem(products[index + 1], pattern.isEven ? 1 : 2),
        ]);
        index += count;
        pattern++;
      }
    }

    return rows;
  }
}

class _BentoItem {
  final Product product;
  final int span;

  const _BentoItem(this.product, this.span);
}

class _BentoProductRow extends StatelessWidget {
  final List<_BentoItem> items;
  final ValueChanged<Product> onTap;

  const _BentoProductRow({
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final featured = items.any((item) => item.product.isFeatured);
    final hasWideTile = items.any((item) => item.span > 1);
    final height = featured
        ? 352.0
        : hasWideTile
            ? 316.0
            : 292.0;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const SizedBox(width: 12),
            Expanded(
              flex: items[index].span,
              child: ProductCard(
                product: items[index].product,
                onTap: () => onTap(items[index].product),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
