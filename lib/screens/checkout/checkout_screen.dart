import 'package:flutter/material.dart';
import 'package:flutter_pos_offline/screens/checkout/payment_success_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pos_offline/services/pos_provider.dart';
import 'package:flutter_pos_offline/utils/constants.dart';

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

  String _selectedPaymentMethod = 'cash';
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'cash', 'name': 'Tunai', 'icon': Icons.money},
    {'id': 'card', 'name': 'Kartu', 'icon': Icons.credit_card},
    {'id': 'qris', 'name': 'QRIS', 'icon': Icons.qr_code},
    {'id': 'ewallet', 'name': 'E-Wallet', 'icon': Icons.account_balance_wallet},
  ];

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
        builder: (context, posProvider, child) {
          final formatter = NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          );

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Summary
                      _buildOrderSummary(posProvider, formatter),

                      const SizedBox(height: 24),

                      // Customer Information
                      _buildCustomerInfo(),

                      const SizedBox(height: 24),

                      // Payment Method
                      _buildPaymentMethod(),

                      const SizedBox(height: 24),

                      // Payment Amount (for cash)
                      if (_selectedPaymentMethod == 'cash')
                        _buildPaymentAmount(posProvider.cartTotal, formatter),
                    ],
                  ),
                ),
              ),

              // Process Payment Button
              _buildProcessButton(posProvider, formatter),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(PosProvider posProvider, NumberFormat formatter) {
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

            // Items
            ...posProvider.cartItems
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${item.product.name} x${item.quantity}'),
                        ),
                        Text(
                          formatter.format(item.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),

            const Divider(),

            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(formatter.format(posProvider.cartSubtotal)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pajak (10%):'),
                Text(formatter.format(posProvider.cartTax)),
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
                  formatter.format(posProvider.cartTotal),
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
              decoration: InputDecoration(
                labelText: 'Nama Pelanggan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primaryGreen,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Nomor Telepon',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primaryGreen,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
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
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final method = _paymentMethods[index];
                final isSelected = _selectedPaymentMethod == method['id'];

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = method['id'];
                      if (_selectedPaymentMethod != 'cash') {
                        _amountController.clear();
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.grey,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? AppColors.lightGreen.withOpacity(0.1)
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          method['icon'],
                          color: isSelected
                              ? AppColors.primaryGreen
                              : AppColors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          method['name'],
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.grey,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentAmount(double total, NumberFormat formatter) {
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
              decoration: InputDecoration(
                labelText: 'Jumlah yang dibayar',
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primaryGreen,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Quick amount buttons
            Row(
              children: [
                _buildQuickAmountButton(total, formatter),
                const SizedBox(width: 8),
                _buildQuickAmountButton(total + 50000, formatter),
                const SizedBox(width: 8),
                _buildQuickAmountButton(total + 100000, formatter),
              ],
            ),

            // Change calculation
            if (_amountController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildChangeDisplay(total, formatter),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(double amount, NumberFormat formatter) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          _amountController.text = amount.toInt().toString();
          setState(() {});
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primaryGreen),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          formatter.format(amount),
          style: const TextStyle(color: AppColors.primaryGreen, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildChangeDisplay(double total, NumberFormat formatter) {
    final amountPaid = double.tryParse(_amountController.text) ?? 0;
    final change = amountPaid - total;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: change >= 0
            ? AppColors.lightGreen.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
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
            formatter.format(change),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: change >= 0 ? AppColors.primaryGreen : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessButton(PosProvider posProvider, NumberFormat formatter) {
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
          if (_selectedPaymentMethod == 'cash' &&
              _amountController.text.isNotEmpty)
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
                    formatter.format(posProvider.cartTotal),
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
              onPressed: _isProcessing ? null : _processPayment,
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

  void _processPayment() async {
    final posProvider = context.read<PosProvider>();

    // Validation
    if (_selectedPaymentMethod == 'cash' && _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah pembayaran'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == 'cash') {
      final amountPaid = double.tryParse(_amountController.text) ?? 0;
      if (amountPaid < posProvider.cartTotal) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jumlah bayar tidak mencukupi'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final amountPaid = _selectedPaymentMethod == 'cash'
          ? (double.tryParse(_amountController.text) ?? posProvider.cartTotal)
          : posProvider.cartTotal;

      final transactionId = await posProvider.processTransaction(
        paymentMethod: _selectedPaymentMethod,
        amountPaid: amountPaid,
        customerName: _customerNameController.text.isEmpty
            ? null
            : _customerNameController.text,
        customerPhone: _customerPhoneController.text.isEmpty
            ? null
            : _customerPhoneController.text,
      );

      // Navigate to success screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              transactionId: transactionId,
              paymentMethod: _selectedPaymentMethod,
              amountPaid: amountPaid,
              change: amountPaid - posProvider.cartTotal,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}
