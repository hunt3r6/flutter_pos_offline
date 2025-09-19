import 'package:flutter/material.dart';
import 'package:flutter_pos_offline/screens/checkout/reciept_screen.dart';
import 'package:flutter_pos_offline/screens/main_screen.dart';
import 'package:flutter_pos_offline/utils/constants.dart';
import 'package:flutter_pos_offline/utils/payment_method.dart';
import 'package:intl/intl.dart';

class PaymentSuccessScreen extends StatelessWidget {
  PaymentSuccessScreen({
    super.key,
    required this.transactionId,
    required this.paymentMethod,
    required this.amountPaid,
    required this.change,
  });

  final int transactionId;
  final String paymentMethod;
  final double amountPaid;
  final double change;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSuccessIcon(),
              const SizedBox(height: 32),
              const Text(
                'Pembayaran Berhasil!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'ID Transaksi: TRX${transactionId.toString().padLeft(6, '0')}',
                style: const TextStyle(fontSize: 16, color: AppColors.grey),
              ),
              const SizedBox(height: 32),
              _buildPaymentDetailsCard(),
              const SizedBox(height: 32),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 60),
    );
  }

  Widget _buildPaymentDetailsCard() {
    final paymentMethodLabel = PaymentMethodHelper.labelFor(paymentMethod);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _PaymentDetailRow(
              label: 'Metode Pembayaran',
              value: paymentMethodLabel,
            ),
            const SizedBox(height: 12),
            _PaymentDetailRow(
              label: 'Jumlah Bayar',
              value: _currencyFormatter.format(amountPaid),
            ),
            if (change > 0) ...[
              const SizedBox(height: 12),
              _PaymentDetailRow(
                label: 'Kembalian',
                value: _currencyFormatter.format(change),
                valueColor: AppColors.primaryGreen,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _navigateToReceipt(context),
            icon: const Icon(Icons.receipt, color: Colors.white),
            label: const Text(
              'Lihat Struk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _navigateToHome(context),
            icon: const Icon(Icons.home, color: AppColors.primaryGreen),
            label: const Text(
              'Kembali ke Beranda',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryGreen, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToReceipt(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(transactionId: transactionId),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }
}

class _PaymentDetailRow extends StatelessWidget {
  const _PaymentDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: AppColors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
