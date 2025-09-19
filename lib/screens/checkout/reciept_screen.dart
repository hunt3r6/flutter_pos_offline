import 'package:flutter/material.dart';
import 'package:flutter_pos_offline/models/models.dart';
import 'package:flutter_pos_offline/services/transaction_service.dart';
import 'package:flutter_pos_offline/utils/constants.dart';
import 'package:flutter_pos_offline/utils/payment_method.dart';
import 'package:intl/intl.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key, required this.transactionId});

  final int transactionId;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final TransactionService _transactionService = TransactionService();

  Transaction? _transaction;
  bool _isLoading = true;
  late final NumberFormat _currencyFormatter;
  late final DateFormat _dateFormatter;

  @override
  void initState() {
    super.initState();
    _currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    try {
      final loadedTransaction = await _transactionService.getTransactionById(
        widget.transactionId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _transaction = loadedTransaction;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading transaction: $error')),
      );
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
            onPressed: () =>
                _showComingSoon(context, 'Fitur share akan ditambahkan'),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () =>
                _showComingSoon(context, 'Fitur print akan ditambahkan'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transaction == null) {
      return const Center(child: Text('Transaction not found'));
    }

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: _buildReceipt(_transaction!),
      ),
    );
  }

  Widget _buildReceipt(Transaction transaction) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
          _buildTransactionInfo(transaction),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'ITEM PEMBELIAN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),
          ...transaction.items.map(_buildItemRow),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _buildTotals(transaction),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _buildPaymentInfo(transaction),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
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

  Widget _buildTransactionInfo(Transaction transaction) {
    return Column(
      children: [
        _buildInfoRow('No. Transaksi:', transaction.receiptNumber),
        const SizedBox(height: 4),
        _buildInfoRow('Tanggal:', _dateFormatter.format(transaction.createdAt)),
        if (transaction.customerName != null) ...[
          const SizedBox(height: 4),
          _buildInfoRow('Pelanggan:', transaction.customerName!),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }

  Widget _buildItemRow(TransactionItem item) {
    return Padding(
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
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_currencyFormatter.format(item.price)} x ${item.quantity}',
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _currencyFormatter.format(item.subtotal),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(Transaction transaction) {
    return Column(
      children: [
        _buildInfoRow(
          'Subtotal:',
          _currencyFormatter.format(transaction.subtotal),
        ),
        const SizedBox(height: 4),
        _buildInfoRow('Pajak:', _currencyFormatter.format(transaction.tax)),
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
              _currencyFormatter.format(transaction.total),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(Transaction transaction) {
    return Column(
      children: [
        _buildInfoRow(
          'Pembayaran:',
          PaymentMethodHelper.labelFor(transaction.paymentMethod),
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          'Bayar:',
          _currencyFormatter.format(transaction.amountPaid),
        ),
        if (transaction.change > 0) ...[
          const SizedBox(height: 4),
          _buildInfoRow(
            'Kembalian:',
            _currencyFormatter.format(transaction.change),
          ),
        ],
      ],
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
