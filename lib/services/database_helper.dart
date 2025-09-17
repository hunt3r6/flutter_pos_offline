import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'pos_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel Categories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        color INTEGER NOT NULL,
        icon TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabel Products
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        category TEXT NOT NULL,
        barcode TEXT,
        image_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabel Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total REAL NOT NULL,
        tax REAL DEFAULT 0.0,
        discount REAL DEFAULT 0.0,
        payment_method TEXT NOT NULL,
        amount_paid REAL NOT NULL,
        change_amount REAL DEFAULT 0.0,
        customer_name TEXT,
        customer_phone TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabel Transaction Items
    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        discount REAL DEFAULT 0.0,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);
    // Insert sample products - TAMBAHKAN BARIS INI
    await _insertSampleProducts(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      {
        'name': 'Makanan',
        'description': 'Produk makanan dan snack',
        'color': 0xFF4CAF50,
        'icon': 'restaurant',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Minuman',
        'description': 'Minuman dan beverages',
        'color': 0xFF2196F3,
        'icon': 'local_drink',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Elektronik',
        'description': 'Produk elektronik',
        'color': 0xFFFF9800,
        'icon': 'devices',
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', category);
    }
  }

  // Insert sample products
  Future<void> _insertSampleProducts(Database db) async {
    final sampleProducts = [
      {
        'name': 'Nasi Gudeg',
        'price': 15000.0,
        'stock': 50,
        'category': 'Makanan',
        'barcode': '123456789001',
        'image_path': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Sate Ayam',
        'price': 20000.0,
        'stock': 30,
        'category': 'Makanan',
        'barcode': '123456789002',
        'image_path': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Es Teh Manis',
        'price': 5000.0,
        'stock': 100,
        'category': 'Minuman',
        'barcode': '123456789003',
        'image_path': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Jus Jeruk',
        'price': 10000.0,
        'stock': 80,
        'category': 'Minuman',
        'barcode': '123456789004',
        'image_path': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Powerbank 10000mAh',
        'price': 150000.0,
        'stock': 15,
        'category': 'Elektronik',
        'barcode': '123456789005',
        'image_path': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Kabel USB Type-C',
        'price': 25000.0,
        'stock': 40,
        'category': 'Elektronik',
        'barcode': '123456789006',
        'image_path': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Roti Bakar',
        'price': 8000.0,
        'stock': 25,
        'category': 'Makanan',
        'barcode': '123456789007',
        'image_path': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Kopi Hitam',
        'price': 7000.0,
        'stock': 60,
        'category': 'Minuman',
        'barcode': '123456789008',
        'image_path': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    for (var product in sampleProducts) {
      await db.insert('products', product);
    }
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Tambahkan method untuk clear database - hanya untuk development
  Future<void> clearDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'pos_offline.db');

    // Delete database file
    await deleteDatabase(path);
    _database = null;
  }
}
