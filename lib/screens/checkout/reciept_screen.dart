import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pos_offline/services/transaction_service.dart';
import 'package:flutter_pos_offline/utils/constants.dart';
import 'package:flutter_pos_offline/models/models.dart';

class ReceiptScreen extends StatefulWidget {
  final int transactionId;

  const ReceiptScreen({super.key, required this.transactionId});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  Transaction? transaction;
  bool isLoading = true;
  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  void _loadTransaction() async {
    try {
      final loadedTransaction = await _transactionService.getTransactionById(
        widget.transactionId,
      );
      setState(() {
        transaction = loadedTransaction;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading transaction: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk Pembelian'),
        backgroundColor: AppColors.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur share akan ditambahkan')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // TODO: Implement print functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur print akan ditambahkan')),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transaction == null
          ? const Center(child: Text('Transaction not found'))
          : SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: _buildReceipt(),
              ),
            ),
    );
  }

  Widget _buildReceipt() {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          const Text(
            'POS OFFLINE',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
          const Text(
            'Jl. Contoh No. 123, Jakarta',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const Text(
            'Telp: (021) 1234-5678',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),

          const SizedBox(height: 20),
          const Divider(thickness: 2),
          const SizedBox(height: 12),

          // Transaction Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'No. Transaksi:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(transaction!.receiptNumber),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tanggal:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(dateFormatter.format(transaction!.createdAt)),
            ],
          ),

          if (transaction!.customerName != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pelanggan:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(transaction!.customerName!),
              ],
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Items
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'ITEM PEMBELIAN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),

          ...transaction!.items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${formatter.format(item.price)} x ${item.quantity}',
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          formatter.format(item.subtotal),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Totals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:'),
              Text(formatter.format(transaction!.subtotal)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pajak:'),
              Text(formatter.format(transaction!.tax)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 2),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                formatter.format(transaction!.total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Payment Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pembayaran:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_getPaymentMethodName(transaction!.paymentMethod)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bayar:'),
              Text(formatter.format(transaction!.amountPaid)),
            ],
          ),
          if (transaction!.change > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kembalian:'),
                Text(formatter.format(transaction!.change)),
              ],
            ),
          ],

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          // Footer
          const Text(
            'Terima kasih atas kunjungan Anda!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Barang yang sudah dibeli tidak dapat dikembalikan',
            style: TextStyle(fontSize: 12, color: AppColors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'cash':
        return 'Tunai';
      case 'card':
        return 'Kartu';
      case 'qris':
        return 'QRIS';
      case 'ewallet':
        return 'E-Wallet';
      default:
        return method;
    }
  }
}
