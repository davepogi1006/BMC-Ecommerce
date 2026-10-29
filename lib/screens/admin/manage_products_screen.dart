import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/format.dart';
import '../../widgets/product_card.dart';
import '../../widgets/tech_ui.dart';
import 'add_product_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final _service = FirestoreService();
  final Set<String> _busyProductIds = {};

  Future<void> _editProduct(Product product) async {
    if (!context.read<AuthProvider>().canAddProducts) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddProductScreen(product: product),
    ));
  }

  Future<void> _deleteProduct(Product product) async {
    if (!context.read<AuthProvider>().canAddProducts) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
            '“${product.name}” will be removed from the shop. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() => _busyProductIds.add(product.id));
    try {
      await _service.deleteProduct(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete product: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyProductIds.remove(product.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return Scaffold(
      appBar: AppBar(title: const Text('Manage products')),
      body: StreamBuilder<List<Product>>(
        stream: _service.streamProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Could not load products: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data!;
          if (products.isEmpty) {
            return const Center(child: Text('No products yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: products.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: TechPageIntro(
                    eyebrow: isAdmin
                        ? 'Administration / catalog'
                        : 'Seller / catalog',
                    title: 'Manage products.',
                    description: isAdmin
                        ? 'Edit availability, product information, and shop highlights.'
                        : 'Edit or remove product listings from the shop.',
                  ),
                );
              }
              final product = products[index - 1];
              final busy = _busyProductIds.contains(product.id);
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: SizedBox(
                    width: 52,
                    height: 52,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ProductImage(url: product.imageUrl),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(product.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (product.isFeatured) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: peso(product.price),
                          style: TextStyle(
                            color: AppTheme.priceColor(
                                Theme.of(context).brightness),
                            fontFamily: 'monospace',
                          ),
                        ),
                        TextSpan(
                          text: ' · Stock: ${product.stock}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : PopupMenuButton<String>(
                          tooltip: 'Product actions',
                          onSelected: (action) {
                            if (action == 'edit') {
                              _editProduct(product);
                            } else if (action == 'delete') {
                              _deleteProduct(product);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Edit'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.delete_outline),
                                title: Text('Delete'),
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
