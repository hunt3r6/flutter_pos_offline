import 'package:flutter/material.dart';
import 'package:flutter_pos_offline/models/models.dart';
import 'package:flutter_pos_offline/screens/search/advanced_search_screen.dart';
import 'package:flutter_pos_offline/services/pos_provider.dart';
import 'package:flutter_pos_offline/services/search_service.dart';
import 'package:flutter_pos_offline/utils/constants.dart';
import 'package:flutter_pos_offline/widgets/cart_panel.dart';
import 'package:flutter_pos_offline/widgets/product_grid.dart';
import 'package:flutter_pos_offline/widgets/search_widget.dart';
import 'package:provider/provider.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final SearchService _searchService = SearchService();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  void _performSearch(String query) async {
    setState(() {
      _searchQuery = query;
    });

    try {
      await _searchService.searchProducts(
        query,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          Expanded(
            child: Consumer<PosProvider>(
              builder: (context, posProvider, child) {
                return _buildProductContent(posProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        selectedColor: AppColors.lightGreen,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.primaryGreen,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Kasir POS',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: AppColors.primaryGreen,
      elevation: 0,
      actions: [_buildCartAction()],
    );
  }

  Widget _buildCartAction() {
    return Consumer<PosProvider>(
      builder: (context, posProvider, child) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () => _showCartDialog(context),
            ),
            if (posProvider.cartItemCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${posProvider.cartItemCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SearchWidget(
                  hintText: 'Cari produk atau scan barcode...',
                  onSearch: _performSearch,
                  showSuggestions: true,
                  showRecentSearches: true,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _openAdvancedSearch,
                icon: const Icon(Icons.tune, color: AppColors.primaryGreen),
                style: _secondaryActionStyle,
              ),
              IconButton(
                onPressed: _showScannerComingSoon,
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.primaryGreen,
                ),
                style: _secondaryActionStyle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<PosProvider>(
            builder: (context, posProvider, child) {
              return SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip('All', _selectedCategory == 'All'),
                    ...posProvider.categories.map(
                      (category) => _buildCategoryChip(
                        category.name,
                        _selectedCategory == category.name,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductContent(PosProvider posProvider) {
    final filteredProducts = _filterProducts(posProvider);

    if (filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return ProductGrid(
      products: filteredProducts,
      onProductTap: (product) => _handleProductTap(posProvider, product),
    );
  }

  List<Product> _filterProducts(PosProvider posProvider) {
    var filteredProducts = posProvider.products;

    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return product.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (product.barcode?.contains(_searchQuery) ?? false);
      }).toList();
    }

    if (_selectedCategory != 'All') {
      filteredProducts = filteredProducts
          .where((p) => p.category == _selectedCategory)
          .toList();
    }

    return filteredProducts;
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.grey),
          SizedBox(height: 16),
          Text(
            'Belum ada produk',
            style: TextStyle(fontSize: 18, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  void _handleProductTap(PosProvider posProvider, Product product) {
    if (product.stock <= 0) {
      _showSnackBar('${product.name} sudah habis', backgroundColor: Colors.red);
      return;
    }

    final maxQuantity = posProvider.getMaxQuantityForProduct(product.id!);
    if (maxQuantity <= 0) {
      _showSnackBar(
        '${product.name} sudah mencapai batas maksimal di keranjang',
        backgroundColor: Colors.orange,
      );
      return;
    }

    posProvider.addToCart(product);
    _showSnackBar(
      '${product.name} ditambahkan ke keranjang',
      backgroundColor: AppColors.primaryGreen,
      duration: const Duration(seconds: 1),
    );
  }

  ButtonStyle get _secondaryActionStyle {
    return IconButton.styleFrom(
      backgroundColor: AppColors.lightGreen.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _showScannerComingSoon() {
    _showSnackBar('Fitur scanner akan ditambahkan');
  }

  void _openAdvancedSearch() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdvancedSearchScreen()),
    );
  }

  void _showSnackBar(
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  void _showCartDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CartPanel(),
    );
  }
}
