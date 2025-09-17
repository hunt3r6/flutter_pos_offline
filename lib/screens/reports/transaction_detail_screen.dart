import 'package:flutter/material.dart';
import 'package:flutter_pos_offline/screens/checkout/reciept_screen.dart';
import 'package:intl/intl.dart';
import '../../services/transaction_service.dart';
import '../../utils/constants.dart';
import '../../models/models.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int transactionId;

  const TransactionDetailScreen({Key? key, required this.transactionId})
    : super(key: key);

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final TransactionService _transactionService = TransactionService();
  Transaction? transaction;
  bool isLoading = true;

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
        title: Text('Detail Transaksi'),
        backgroundColor: AppColors.primaryGreen,
        actions: [
          if (transaction != null)
            IconButton(
              icon: const Icon(Icons.receipt),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ReceiptScreen(transactionId: widget.transactionId),
                  ),
                );
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transaction == null
          ? const Center(child: Text('Transaction not found'))
          : _buildTransactionDetail(),
    );
  }

  Widget _buildTransactionDetail() {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm:ss');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction Info Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Transaksi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInfoRow('No. Transaksi', transaction!.receiptNumber),
                  _buildInfoRow(
                    'Tanggal',
                    dateFormatter.format(transaction!.createdAt),
                  ),
                  _buildInfoRow(
                    'Metode Bayar',
                    _getPaymentMethodName(transaction!.paymentMethod),
                  ),
                  if (transaction!.customerName != null)
                    _buildInfoRow('Pelanggan', transaction!.customerName!),
                  if (transaction!.customerPhone != null)
                    _buildInfoRow('Telepon', transaction!.customerPhone!),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Items Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item Pembelian',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...transaction!.items
                      .map((item) => _buildItemRow(item, formatter))
                      .toList(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Payment Summary Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Pembayaran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildPaymentRow(
                    'Subtotal',
                    formatter.format(transaction!.subtotal),
                  ),
                  _buildPaymentRow('Pajak', formatter.format(transaction!.tax)),
                  if (transaction!.discount > 0)
                    _buildPaymentRow(
                      'Diskon',
                      '- ${formatter.format(transaction!.discount)}',
                    ),

                  const Divider(thickness: 2),

                  _buildPaymentRow(
                    'Total',
                    formatter.format(transaction!.total),
                    isTotal: true,
                  ),

                  const SizedBox(height: 8),

                  _buildPaymentRow(
                    'Bayar',
                    formatter.format(transaction!.amountPaid),
                  ),
                  if (transaction!.change > 0)
                    _buildPaymentRow(
                      'Kembalian',
                      formatter.format(transaction!.change),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(color: AppColors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(TransactionItem item, NumberFormat formatter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${formatter.format(item.price)} x ${item.quantity}',
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
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
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppColors.primaryGreen : Colors.black,
            ),
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
