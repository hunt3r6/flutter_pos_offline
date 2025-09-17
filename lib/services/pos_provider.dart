import 'package:flutter/material.dart';
import 'package:flutter_pos_offline/models/models.dart';
import 'package:flutter_pos_offline/services/category_service.dart';
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
    // Validasi stok kosong
    if (product.stock <= 0) {
      // Tidak menambahkan, bisa tambahkan notifikasi jika perlu
      return;
    }

    final existingIndex = _cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex != -1) {
      // Cek apakah masih bisa ditambah
      final currentQuantity = _cartItems[existingIndex].quantity;
      if (currentQuantity < product.stock) {
        _cartItems[existingIndex].increaseQuantity();
      } else {
        // Stok tidak mencukupi - bisa tambahkan notifikasi
        return;
      }
    } else {
      // Produk baru, cek stok tersedia
      if (product.stock > 0) {
        _cartItems.add(CartItem(product: product));
      } else {
        return;
      }
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
        // Validasi stok tersedia
        final product = _cartItems[index].product;
        if (quantity <= product.stock) {
          _cartItems[index].setQuantity(quantity);
        } else {
          // Set ke maksimal stok yang tersedia
          _cartItems[index].setQuantity(product.stock);
        }
      }
      notifyListeners();
    }
  }

  bool isProductAvailable(Product product) {
    return product.stock > 0;
  }

  // Get max quantity for a product in cart
  int getMaxQuantityForProduct(int productId) {
    final product = _products.firstWhere((p) => p.id == productId);
    final existingCartItem = _cartItems.where(
      (item) => item.product.id == productId,
    );

    if (existingCartItem.isNotEmpty) {
      final currentQuantity = existingCartItem.first.quantity;
      return product.stock - currentQuantity;
    }

    return product.stock;
  }

  // Validate cart stock before checkout
  List<String> validateCartStock() {
    final errors = <String>[];

    for (var cartItem in _cartItems) {
      // Refresh product data untuk pastikan stok terbaru
      final currentProduct = _products.firstWhere(
        (p) => p.id == cartItem.product.id,
        orElse: () => cartItem.product,
      );

      if (currentProduct.stock <= 0) {
        errors.add('${currentProduct.name} sudah habis');
      } else if (cartItem.quantity > currentProduct.stock) {
        errors.add(
          '${currentProduct.name} hanya tersisa ${currentProduct.stock} item',
        );
      }
    }

    return errors;
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

  // Update category dan reload products
  Future<void> updateCategory(Category category) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _categoryService.updateCategory(category);

      // Reload both categories and products untuk refresh UI
      await loadCategories();
      await loadProducts(); // Penting: reload products juga
    } catch (e) {
      debugPrint('Error updating category: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hapus kategori dan semua produk terkait
  Future<void> deleteCategory(int categoryId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _categoryService.deleteCategory(categoryId);

      if (success) {
        // Reload both categories and products
        await loadCategories();
        await loadProducts(); // Penting: reload products juga
      } else {
        throw Exception('Gagal menghapus kategori');
      }
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
