import '../models/product.dart';

String? validateProductName(String? value) {
  return value == null || value.trim().isEmpty ? 'Enter a product name' : null;
}

String? validateProductPrice(String? value) {
  final price = double.tryParse(value?.trim() ?? '');
  return price == null || !price.isFinite || price <= 0
      ? 'Enter a price above 0'
      : null;
}

String? validateProductStock(String? value) {
  final stock = int.tryParse(value?.trim() ?? '');
  return stock == null || stock < 0 ? 'Enter a whole number 0 or higher' : null;
}

String? validateProductCategory(String? value) {
  return value != null && productCategories.contains(value)
      ? null
      : 'Choose a supported category';
}

String? validateProductImageUrl(String? value) {
  final rawUrl = value?.trim() ?? '';
  final uri = Uri.tryParse(rawUrl);
  return uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty
      ? null
      : 'Enter a valid http or https image URL';
}
