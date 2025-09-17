import 'package:flutter_pos_offline/models/models.dart';
import 'database_helper.dart';

class ProductService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Create product
  Future<int> createProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.insert('products', product.toMap());
  }

  // Get all products
  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Get product by id
  Future<Product?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  // Get product by barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  // Update product
  Future<int> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // Update stock
  Future<int> updateStock(int productId, int newStock) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      {'stock': newStock, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // // Reduce stock (untuk transaksi)
  // Future<bool> reduceStock(int productId, int quantity) async {
  //   final db = await _dbHelper.database;

  //   // Get current stock
  //   final product = await getProductById(productId);
  //   if (product == null || product.stock < quantity) {
  //     return false;
  //   }

  //   final newStock = product.stock - quantity;
  //   await updateStock(productId, newStock);
  //   return true;
  // }

  // Delete product
  Future<int> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Get low stock products
  Future<List<Product>> getLowStockProducts({int threshold = 10}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'stock <= ?',
      whereArgs: [threshold],
      orderBy: 'stock ASC',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Update category name in all products
  Future<int> updateProductsCategory(
    String oldCategoryName,
    String newCategoryName,
  ) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      {
        'category': newCategoryName,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'category = ?',
      whereArgs: [oldCategoryName],
    );
  }

  // Delete products by category (when category is deleted)
  Future<int> deleteProductsByCategory(String categoryName) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'products',
      where: 'category = ?',
      whereArgs: [categoryName],
    );
  }

  // Count products by category
  Future<int> countProductsByCategory(String categoryName) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE category = ?',
      [categoryName],
    );
    return result.first['count'] as int;
  }
}
