import 'package:flutter/material.dart';
import 'package:flutter_pos_offline/screens/cashier/cashier_screen.dart';
import 'package:flutter_pos_offline/screens/products/product_list_screen.dart';
import 'package:flutter_pos_offline/screens/reports/reports_screen.dart';
import 'package:flutter_pos_offline/screens/settings/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pos_offline/utils/constants.dart';
import 'package:flutter_pos_offline/services/pos_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CashierScreen(),
    const ProductListScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize data when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosProvider>().initializeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PosProvider>(
        builder: (context, posProvider, child) {
          if (posProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Initializing POS System...',
                    style: TextStyle(color: AppColors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return _screens[_currentIndex];
        },
      ),
      // Tambahkan FAB untuk reset - HANYA UNTUK DEVELOPMENT
      floatingActionButton: _currentIndex == 3
          ? FloatingActionButton.extended(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset Database'),
                    content: const Text(
                      'Ini akan menghapus semua data dan menambahkan data sample. Lanjutkan?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await context.read<PosProvider>().resetDatabase();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Database berhasil direset dengan data sample',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset DB'),
              backgroundColor: AppColors.primaryGreen,
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale),
              label: 'Kasir',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory),
              label: 'Produk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Laporan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}
