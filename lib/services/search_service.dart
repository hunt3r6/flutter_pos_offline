import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pos_offline/models/models.dart';
import 'product_service.dart';
import 'transaction_service.dart';

class SearchService {
  final ProductService _productService = ProductService();
  final TransactionService _transactionService = TransactionService();
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  // Search Products
  Future<List<Product>> searchProducts(String query, {String? category}) async {
    if (query.trim().isEmpty) {
      return category != null
          ? await _productService.getProductsByCategory(category)
          : await _productService.getAllProducts();
    }

    // Save to recent searches
    await _saveRecentSearch(query);

    // Check if query is barcode (numeric)
    if (RegExp(r'^\d+$').hasMatch(query.trim())) {
      final productByBarcode = await _productService.getProductByBarcode(
        query.trim(),
      );
      if (productByBarcode != null) {
        return [productByBarcode];
      }
    }

    // Text search
    var products = await _productService.searchProducts(query);

    // Filter by category if specified
    if (category != null && category != 'All') {
      products = products.where((p) => p.category == category).toList();
    }

    return products;
  }

  // Search Transactions
  Future<List<Transaction>> searchTransactions(String query) async {
    if (query.trim().isEmpty) {
      return await _transactionService.getAllTransactions();
    }

    await _saveRecentSearch(query);

    final allTransactions = await _transactionService.getAllTransactions();

    return allTransactions.where((transaction) {
      final searchLower = query.toLowerCase();

      return transaction.receiptNumber.toLowerCase().contains(searchLower) ||
          (transaction.customerName?.toLowerCase().contains(searchLower) ??
              false) ||
          (transaction.customerPhone?.contains(query) ?? false) ||
          transaction.paymentMethod.toLowerCase().contains(searchLower);
    }).toList();
  }

  // Advanced Product Search
  Future<List<Product>> advancedProductSearch({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    int? minStock,
    int? maxStock,
    bool? lowStock,
  }) async {
    var products = await _productService.getAllProducts();

    // Apply filters
    if (query != null && query.trim().isNotEmpty) {
      final searchLower = query.toLowerCase();
      products = products
          .where(
            (p) =>
                p.name.toLowerCase().contains(searchLower) ||
                (p.barcode?.contains(query) ?? false),
          )
          .toList();
    }

    if (category != null && category != 'All') {
      products = products.where((p) => p.category == category).toList();
    }

    if (minPrice != null) {
      products = products.where((p) => p.price >= minPrice).toList();
    }

    if (maxPrice != null) {
      products = products.where((p) => p.price <= maxPrice).toList();
    }

    if (minStock != null) {
      products = products.where((p) => p.stock >= minStock).toList();
    }

    if (maxStock != null) {
      products = products.where((p) => p.stock <= maxStock).toList();
    }

    if (lowStock == true) {
      products = products.where((p) => p.stock <= 10).toList();
    }

    return products;
  }

  // Get search suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    final products = await _productService.getAllProducts();
    final suggestions = <String>{};

    for (var product in products) {
      if (product.name.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(product.name);
      }
      if (product.category.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(product.category);
      }
    }

    return suggestions.take(5).toList();
  }

  // Recent searches
  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey) ?? [];
  }

  Future<void> _saveRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    var recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];

    // Remove if already exists
    recentSearches.remove(query);

    // Add to beginning
    recentSearches.insert(0, query);

    // Keep only max number of searches
    if (recentSearches.length > _maxRecentSearches) {
      recentSearches = recentSearches.take(_maxRecentSearches).toList();
    }

    await prefs.setStringList(_recentSearchesKey, recentSearches);
  }

  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }
}
