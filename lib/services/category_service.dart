import 'package:flutter_pos_offline/models/models.dart';
import 'package:flutter_pos_offline/services/product_service.dart';
import 'database_helper.dart';

class CategoryService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ProductService _productService = ProductService();

  // Get all categories
  Future<List<Category>> getAllCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  // Create category
  Future<int> createCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.insert('categories', category.toMap());
  }

  // Update category dengan cascade update ke products
  Future<int> updateCategory(Category category) async {
    final db = await _dbHelper.database;

    // Get old category name untuk update products
    final oldCategoryMaps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [category.id],
      limit: 1,
    );

    if (oldCategoryMaps.isNotEmpty) {
      final oldCategoryName = oldCategoryMaps.first['name'] as String;

      // Update category
      final result = await db.update(
        'categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );

      // Update all products yang menggunakan kategori ini
      if (oldCategoryName != category.name) {
        await _productService.updateProductsCategory(
          oldCategoryName,
          category.name,
        );
      }

      return result;
    }

    return 0;
  }

  // Delete category dengan handling products
  Future<bool> deleteCategory(int id) async {
    final db = await _dbHelper.database;

    // Get category name first
    final categoryMaps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (categoryMaps.isEmpty) return false;

    final categoryName = categoryMaps.first['name'] as String;

    // Check if there are products using this category
    final productCount = await _productService.countProductsByCategory(
      categoryName,
    );

    if (productCount > 0) {
      // You can either:
      // 1. Prevent deletion (return false)
      // 2. Move products to "Uncategorized"
      // 3. Delete products along with category

      // Option 2: Move to "Uncategorized"
      await _productService.updateProductsCategory(
        categoryName,
        'Uncategorized',
      );
    }

    // Delete category
    final result = await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    return result > 0;
  }

  // Get category by name
  Future<Category?> getCategoryByName(String name) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }
}
