import 'package:flutter_pos_offline/models/models.dart';
import 'database_helper.dart';
import 'product_service.dart';

class TransactionService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ProductService _productService = ProductService();

  // Create transaction with items
  Future<int> createTransaction(
    Transaction transaction,
    List<CartItem> cartItems,
  ) async {
    final db = await _dbHelper.database;
    int transactionId = 0;

    await db.transaction((txn) async {
      // Insert transaction
      transactionId = await txn.insert('transactions', {
        'total': transaction.total,
        'tax': transaction.tax,
        'discount': transaction.discount,
        'payment_method': transaction.paymentMethod,
        'amount_paid': transaction.amountPaid,
        'change_amount': transaction.change, // Fix: sesuaikan dengan schema
        'customer_name': transaction.customerName,
        'customer_phone': transaction.customerPhone,
        'notes': transaction.notes,
        'created_at': transaction.createdAt.toIso8601String(),
      });

      // Insert transaction items and update stock
      for (var cartItem in cartItems) {
        final transactionItem = TransactionItem(
          transactionId: transactionId,
          productId: cartItem.product.id!,
          productName: cartItem.product.name,
          price: cartItem.product.price,
          quantity: cartItem.quantity,
          discount: cartItem.discount,
        );

        await txn.insert('transaction_items', transactionItem.toMap());

        // Update stock
        final currentProduct = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [cartItem.product.id],
          limit: 1,
        );

        if (currentProduct.isNotEmpty) {
          final currentStock = currentProduct.first['stock'] as int;
          final newStock = currentStock - cartItem.quantity;

          await txn.update(
            'products',
            {'stock': newStock, 'updated_at': DateTime.now().toIso8601String()},
            where: 'id = ?',
            whereArgs: [cartItem.product.id],
          );
        }
      }
    });

    return transactionId;
  }

  // Get all transactions
  Future<List<Transaction>> getAllTransactions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  // Get transaction by id with items
  Future<Transaction?> getTransactionById(int id) async {
    final db = await _dbHelper.database;

    // Get transaction
    final List<Map<String, dynamic>> transactionMaps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (transactionMaps.isEmpty) return null;

    final transaction = Transaction.fromMap(transactionMaps.first);

    // Get transaction items
    final List<Map<String, dynamic>> itemMaps = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [id],
    );

    final items = List.generate(
      itemMaps.length,
      (i) => TransactionItem.fromMap(itemMaps[i]),
    );

    return transaction.copyWith(items: items);
  }

  // Get transactions by date range
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  // Get today's transactions
  Future<List<Transaction>> getTodayTransactions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getTransactionsByDateRange(startOfDay, endOfDay);
  }

  // Get sales summary
  Future<Map<String, dynamic>> getSalesSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'WHERE created_at BETWEEN ? AND ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_transactions,
        SUM(total) as total_sales,
        AVG(total) as average_sale,
        SUM(tax) as total_tax,
        SUM(discount) as total_discount
      FROM transactions 
      $whereClause
    ''', whereArgs);

    return result.first;
  }

  // Delete transaction (soft delete - mark as cancelled)
  Future<int> cancelTransaction(int id) async {
    final db = await _dbHelper.database;
    // In real app, you might want to add a 'status' column and mark as cancelled
    // For now, we'll just delete
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
