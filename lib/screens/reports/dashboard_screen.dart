import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/transaction_service.dart';
import '../../services/product_service.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TransactionService _transactionService = TransactionService();
  final ProductService _productService = ProductService();

  Map<String, dynamic>? _todaySummary;
  List<Transaction>? _recentTransactions;
  List<Product>? _lowStockProducts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Load today's summary
      final todaySummary = await _transactionService.getSalesSummary(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      // Load recent transactions (last 5)
      final allTransactions = await _transactionService.getAllTransactions();
      final recentTransactions = allTransactions.take(5).toList();

      // Load low stock products
      final lowStockProducts = await _productService.getLowStockProducts(
        threshold: 10,
      );

      setState(() {
        _todaySummary = todaySummary;
        _recentTransactions = recentTransactions;
        _lowStockProducts = lowStockProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sales Summary Cards
            _buildSalesSummary(),

            const SizedBox(height: 24),

            // Recent Transactions
            _buildRecentTransactions(),

            const SizedBox(height: 24),

            // Low Stock Alert
            _buildLowStockAlert(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesSummary() {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final totalSales = (_todaySummary?['total_sales'] ?? 0.0) as double;
    final totalTransactions =
        (_todaySummary?['total_transactions'] ?? 0) as int;
    final averageSale = (_todaySummary?['average_sale'] ?? 0.0) as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Penjualan Hari Ini',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Penjualan',
                value: formatter.format(totalSales),
                icon: Icons.attach_money,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Transaksi',
                value: totalTransactions.toString(),
                icon: Icons.receipt,
                color: Colors.blue,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildSummaryCard(
          title: 'Rata-rata per Transaksi',
          value: formatter.format(averageSale),
          icon: Icons.trending_up,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: AppColors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaksi Terbaru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            TextButton(
              onPressed: () {
                // Switch to transaction tab
                DefaultTabController.of(context).animateTo(1);
              },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (_recentTransactions?.isEmpty ?? true)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      size: 48,
                      color: AppColors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada transaksi hari ini',
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._recentTransactions!
              .take(3)
              .map((transaction) => _buildTransactionItem(transaction))
              .toList(),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final timeFormatter = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.lightGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.receipt,
            color: AppColors.primaryGreen,
            size: 20,
          ),
        ),
        title: Text(
          transaction.receiptNumber,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(timeFormatter.format(transaction.createdAt)),
        trailing: Text(
          formatter.format(transaction.total),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockAlert() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stok Menipis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 12),

        if (_lowStockProducts?.isEmpty ?? true)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Semua produk stoknya aman',
                      style: TextStyle(color: AppColors.primaryGreen),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._lowStockProducts!
              .map(
                (product) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('Kategori: ${product.category}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Stok: ${product.stock}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
      ],
    );
  }
}
