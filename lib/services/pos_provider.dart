import 'package:flutter/material.dart';
import 'package:flutter_pos_offline/models/models.dart';
import 'package:flutter_pos_offline/services/categoty_service.dart';
import 'package:flutter_pos_offline/services/database_helper.dart';
import 'package:flutter_pos_offline/services/product_service.dart';
import 'package:flutter_pos_offline/services/transaction_service.dart';

class PosProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final TransactionService _transactionService = TransactionService();
  final CategoryService _categoryService = CategoryService();

  // Products
  List<Product> _products = [];
  List<Product> get products => _products;

  // Categories
  List<Category> _categories = [];
  List<Category> get categories => _categories;

  // Cart
  List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => _cartItems;

  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Cart calculations
  double get cartSubtotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  double get cartTax => cartSubtotal * 0.1; // 10% tax
  double get cartTotal => cartSubtotal + cartTax;
  int get cartItemCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  // Initialize data
  Future<void> initializeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadProducts();
      await loadCategories();
    } catch (e) {
      debugPrint('Error initializing data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load products
  Future<void> loadProducts() async {
    _products = await _productService.getAllProducts();
    notifyListeners();
  }

  // Load categories
  Future<void> loadCategories() async {
    _categories = await _categoryService.getAllCategories();
    notifyListeners();
  }

  // Add to cart
  void addToCart(Product product) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex != -1) {
      _cartItems[existingIndex].increaseQuantity();
    } else {
      _cartItems.add(CartItem(product: product));
    }
    notifyListeners();
  }

  // Remove from cart
  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  // Update cart item quantity
  void updateCartItemQuantity(int productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].setQuantity(quantity);
      }
      notifyListeners();
    }
  }

  // Clear cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // Process transaction
  Future<int> processTransaction({
    required String paymentMethod,
    required double amountPaid,
    String? customerName,
    String? customerPhone,
  }) async {
    if (_cartItems.isEmpty) throw Exception('Cart is empty');

    final transaction = Transaction(
      total: cartTotal,
      tax: cartTax,
      discount: 0.0,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      change: amountPaid - cartTotal,
      customerName: customerName,
      customerPhone: customerPhone,
    );

    final transactionId = await _transactionService.createTransaction(
      transaction,
      _cartItems,
    );

    // Clear cart and reload products (to update stock)
    clearCart();
    await loadProducts();

    return transactionId;
  }

  // Tambahkan method ini di PosProvider untuk development purposes
  Future<void> resetDatabase() async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseHelper().clearDatabase();
      await initializeData();
    } catch (e) {
      debugPrint('Error resetting database: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Tambahkan methods ini di class PosProvider

  // Product CRUD
  Future<void> addProduct(Product product) async {
    await _productService.createProduct(product);
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await _productService.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(int productId) async {
    await _productService.deleteProduct(productId);
    await loadProducts();
  }

  // Category CRUD
  Future<void> addCategory(Category category) async {
    await _categoryService.createCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _categoryService.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int categoryId) async {
    await _categoryService.deleteCategory(categoryId);
    await loadCategories();
  }
}
