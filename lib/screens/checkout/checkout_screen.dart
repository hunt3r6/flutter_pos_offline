import 'package:flutter/material.dart';
import 'package:flutter_pos_offline/screens/checkout/payment_success_screen.dart';
import 'package:flutter_pos_offline/services/pos_provider.dart';
import 'package:flutter_pos_offline/utils/constants.dart';
import 'package:flutter_pos_offline/utils/payment_method.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();

  late final NumberFormat _currencyFormatter;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _isProcessing = false;

  bool get _isCashPayment => _selectedPaymentMethod == PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.primaryGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<PosProvider>(
        builder: (context, posProvider, _) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderSummary(posProvider),
                      const SizedBox(height: 24),
                      _buildCustomerInfo(),
                      const SizedBox(height: 24),
                      _buildPaymentMethod(),
                      if (_isCashPayment) ...[
                        const SizedBox(height: 24),
                        _buildPaymentAmount(posProvider.cartTotal),
                      ],
                    ],
                  ),
                ),
              ),
              _buildProcessButton(posProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(PosProvider posProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Pesanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            ...posProvider.cartItems.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item.product.name} x${item.quantity}'),
                    ),
                    Text(
                      _currencyFormatter.format(item.subtotal),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(_currencyFormatter.format(posProvider.cartSubtotal)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pajak (10%):'),
                Text(_currencyFormatter.format(posProvider.cartTax)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _currencyFormatter.format(posProvider.cartTotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Pelanggan (Opsional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customerNameController,
              decoration: _textFieldDecoration('Nama Pelanggan'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: _textFieldDecoration('Nomor Telepon'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _textFieldDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metode Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3,
              ),
              itemCount: PaymentMethod.values.length,
              itemBuilder: (context, index) {
                final method = PaymentMethod.values[index];
                final isSelected = _selectedPaymentMethod == method;
                return _PaymentMethodTile(
                  method: method,
                  isSelected: isSelected,
                  onTap: () => _onPaymentMethodSelected(method),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentAmount(double total) {
    final quickAmounts = <double>[total, total + 50000, total + 100000];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jumlah Bayar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: _textFieldDecoration(
                'Jumlah yang dibayar',
              ).copyWith(prefixText: 'Rp '),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (int i = 0; i < quickAmounts.length; i++) ...[
                  Expanded(child: _buildQuickAmountButton(quickAmounts[i])),
                  if (i < quickAmounts.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
            if (_amountController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildChangeDisplay(total),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(double amount) {
    return OutlinedButton(
      onPressed: () => _onQuickAmountSelected(amount),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primaryGreen),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        _currencyFormatter.format(amount),
        style: const TextStyle(color: AppColors.primaryGreen, fontSize: 12),
      ),
    );
  }

  void _onQuickAmountSelected(double amount) {
    _amountController.text = amount.toInt().toString();
    setState(() {});
  }

  Widget _buildChangeDisplay(double total) {
    final amountPaid = double.tryParse(_amountController.text) ?? 0;
    final change = amountPaid - total;
    final changeIsPositive = change >= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: changeIsPositive
            ? AppColors.lightGreen.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Kembalian:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            _currencyFormatter.format(change),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: changeIsPositive ? AppColors.primaryGreen : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessButton(PosProvider posProvider) {
    final total = posProvider.cartTotal;
    final shouldShowCashSummary =
        _isCashPayment && _amountController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (shouldShowCashSummary)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Bayar:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _currencyFormatter.format(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _validateAndProcessPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Proses Pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPaymentMethodSelected(PaymentMethod method) {
    if (_selectedPaymentMethod == method) {
      return;
    }
    setState(() {
      _selectedPaymentMethod = method;
      if (!_isCashPayment) {
        _amountController.clear();
      }
    });
  }

  Future<void> _processPayment() async {
    final posProvider = context.read<PosProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final totalDue = posProvider.cartTotal;

    if (_isCashPayment && _amountController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah pembayaran'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isCashPayment) {
      final amountPaid = double.tryParse(_amountController.text) ?? 0;
      if (amountPaid < totalDue) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Jumlah bayar tidak mencukupi'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    final amountPaid = _isCashPayment
        ? (double.tryParse(_amountController.text) ?? totalDue)
        : totalDue;

    try {
      final transactionId = await posProvider.processTransaction(
        paymentMethod: _selectedPaymentMethod.id,
        amountPaid: amountPaid,
        customerName: _customerNameController.text.isEmpty
            ? null
            : _customerNameController.text,
        customerPhone: _customerPhoneController.text.isEmpty
            ? null
            : _customerPhoneController.text,
      );

      if (!mounted) {
        return;
      }

      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            transactionId: transactionId,
            paymentMethod: _selectedPaymentMethod.id,
            amountPaid: amountPaid,
            change: amountPaid - totalDue,
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _validateAndProcessPayment() async {
    final posProvider = context.read<PosProvider>();
    await posProvider.loadProducts();

    if (!mounted) {
      return;
    }

    final stockErrors = posProvider.validateCartStock();
    if (stockErrors.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => _StockErrorDialog(errors: stockErrors),
      );
      return;
    }

    await _processPayment();
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.grey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? AppColors.lightGreen.withValues(alpha: 0.1)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              method.icon,
              color: isSelected ? AppColors.primaryGreen : AppColors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              method.label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryGreen : AppColors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockErrorDialog extends StatelessWidget {
  const _StockErrorDialog({required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Stok Tidak Mencukupi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Item berikut memiliki masalah stok:'),
          const SizedBox(height: 8),
          ...errors.map(
            (error) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(error)),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
