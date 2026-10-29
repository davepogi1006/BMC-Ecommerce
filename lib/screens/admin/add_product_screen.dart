import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/firestore_service.dart';
import '../../utils/product_validators.dart';
import '../../widgets/product_card.dart';
import '../../widgets/tech_ui.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  bool get isEditing => product != null;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _imageUrl = TextEditingController();
  final _tagInput = TextEditingController();
  String? _category;
  final List<String> _tags = [];
  bool _isFeatured = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _name.text = product.name;
      _description.text = product.description;
      _price.text = product.price.toString();
      _stock.text = product.stock.toString();
      _imageUrl.text = product.imageUrl;
      _category = productCategories.contains(product.category)
          ? product.category
          : productCategories.first;
      _tags.addAll(product.tags);
      _isFeatured = product.isFeatured;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _imageUrl.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagInput.text.trim();
    if (tag.isEmpty) return;
    if (tag.length > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Labels must be 30 characters or less.')),
      );
      return;
    }
    if (_tags.any((existing) => existing.toLowerCase() == tag.toLowerCase())) {
      _tagInput.clear();
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagInput.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final product = Product(
        id: widget.product?.id ?? '',
        name: _name.text.trim(),
        description: _description.text.trim(),
        price: double.parse(_price.text),
        category: _category!,
        imageUrl: _imageUrl.text.trim(),
        stock: int.parse(_stock.text),
        tags: List.unmodifiable(_tags),
        isFeatured: _isFeatured,
      );
      if (widget.isEditing) {
        await FirestoreService().updateProduct(product);
      } else {
        await FirestoreService().addProduct(product);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(widget.isEditing ? 'Product updated.' : 'Product added.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      _showSaveError('$e');
    }
  }

  void _showSaveError(String message) {
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Could not save product: $message'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit product' : 'Add product')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                TechPageIntro(
                  eyebrow: 'Administration / catalog',
                  title: widget.isEditing ? 'Edit listing.' : 'Add a product.',
                  description:
                      'Update real catalog details, availability, and product media.',
                ),
                TextFormField(
                  controller: _imageUrl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Product image URL',
                    hintText: 'https://example.com/product-image.jpg',
                    helperText:
                        'Paste a direct image address (JPG, PNG, or WebP).',
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: validateProductImageUrl,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 176,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageUrl.text.trim().isNotEmpty
                      ? ProductImage(url: _imageUrl.text.trim())
                      : const Center(child: Text('Image preview')),
                ),
                const SizedBox(height: 24),
                Text('Essential details',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Product name',
                    hintText: 'e.g. Precision cordless drill',
                  ),
                  validator: validateProductName,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '₱ ',
                    hintText: '0.00',
                  ),
                  validator: validateProductPrice,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Stock quantity',
                    hintText: '0',
                  ),
                  validator: validateProductStock,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: productCategories
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  validator: validateProductCategory,
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
                const SizedBox(height: 24),
                Text('More about this product',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Optional details help customers decide if this is right for them.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    alignLabelWithHint: true,
                    hintText: 'Describe the product and its key details',
                  ),
                ),
                const SizedBox(height: 16),
                Text('Search labels',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Add labels customers can search for, such as “Sale” or “Gaming”.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagInput,
                        maxLength: 30,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Add a label',
                          counterText: '',
                        ),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Add label',
                      onPressed: _addTag,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (_tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final tag in _tags)
                        InputChip(
                          label: Text(tag),
                          onDeleted: () => setState(() => _tags.remove(tag)),
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show in Highlights'),
                  subtitle: const Text(
                      'Featured products appear in a section at the top of the shop.'),
                  value: _isFeatured,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _isFeatured = value),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          widget.isEditing ? 'Save changes' : 'Save product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
