import 'package:flutter/material.dart';
import 'package:flutter_pos_offline/utils/constants.dart';
import 'package:flutter_pos_offline/services/pos_provider.dart';
import 'package:flutter_pos_offline/screens/cashier/cashier_screen.dart';
import 'package:flutter_pos_offline/screens/products/product_list_screen.dart';
import 'package:flutter_pos_offline/screens/reports/reports_screen.dart';
import 'package:flutter_pos_offline/screens/settings/settings_screen.dart';
import 'package:provider/provider.dart';

/// Root screen managing the navigation across cashier, product, reports, and settings tabs.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// Index used to identify the settings tab where the debug FAB lives.
  static const int _settingsTabIndex = 3;

  /// Screens displayed for each navigation item.
  static const List<Widget> _screens = <Widget>[
    CashierScreen(),
    ProductListScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  /// Definition of all bottom navigation destinations.
  static const List<BottomNavigationBarItem>
  _navigationItems = <BottomNavigationBarItem>[
    BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Kasir'),
    BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Produk'),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Laporan'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
  ];

  int _currentIndex = 0;

  /// Trigger initial data load after the first frame is rendered.
  @override
  void initState() {
    super.initState();
    // Initialize data when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PosProvider>().initializeData();
    });
  }

  /// Compose the main scaffold with body, navigation bar, and optional reset FAB.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: _shouldShowResetFab ? _buildResetFab() : null,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Display loading indicator during initialization or the active tab content.
  Widget _buildBody() {
    return Consumer<PosProvider>(
      builder: (_, posProvider, __) {
        return posProvider.isLoading
            ? const _LoadingBody()
            : _screens[_currentIndex];
      },
    );
  }

  /// Floating action button allowing developers to reset the database quickly.
  FloatingActionButton _buildResetFab() {
    return FloatingActionButton.extended(
      onPressed: _onResetDatabasePressed,
      icon: const Icon(Icons.refresh),
      label: const Text('Reset DB'),
      backgroundColor: AppColors.primaryGreen,
    );
  }

  /// Styled bottom navigation bar used to switch between application sections.
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: _navigationItems,
      ),
    );
  }

  /// Update the selected tab while avoiding rebuilds when tapping the same tab.
  void _onTabSelected(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() => _currentIndex = index);
  }

  /// Confirm and execute the database reset flow, showing feedback when complete.
  Future<void> _onResetDatabasePressed() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const _ResetDatabaseDialog(),
    );

    if (!mounted) {
      return;
    }

    if (confirm != true) {
      return;
    }

    // Capture dependencies before awaiting to avoid using BuildContext across async gaps.
    final messenger = ScaffoldMessenger.of(context);
    final posProvider = context.read<PosProvider>();

    await posProvider.resetDatabase();

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Database berhasil direset dengan data sample'),
      ),
    );
  }

  /// Determines whether the reset FAB should be visible on the current tab.
  bool get _shouldShowResetFab => _currentIndex == _settingsTabIndex;
}

/// Simple loading placeholder shown while the POS data initializes.
class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  /// Render the progress indicator and message while data loads.
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
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
}

/// Reusable dialog asking the user to confirm the destructive database reset.
class _ResetDatabaseDialog extends StatelessWidget {
  const _ResetDatabaseDialog();

  /// Build the confirmation dialog with cancel and reset actions.
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
    );
  }
}
