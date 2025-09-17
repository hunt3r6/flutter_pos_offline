import 'package:flutter/material.dart';
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
  String _selectedCategory = 'All';
  String _searchQuery = '';

  void _performSearch(String query) async {
    final searchService = SearchService();
    try {
      final results = await searchService.searchProducts(
        query,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );

      // Update filtered products atau handle search results
      setState(() {
        _searchQuery = query;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text(
          'Kasir POS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        actions: [
          Consumer<PosProvider>(
            builder: (context, posProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      _showCartDialog(context);
                    },
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
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SearchWidget(
                        hintText: 'Cari produk atau scan barcode...',
                        onSearch: (query) {
                          setState(() {
                            _searchQuery = query;
                          });
                          _performSearch(query);
                        },
                        showSuggestions: true,
                        showRecentSearches: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdvancedSearchScreen(),
                        ),
                      ),
                      icon: const Icon(
                        Icons.tune,
                        color: AppColors.primaryGreen,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.lightGreen.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Implement barcode scanner
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fitur scanner akan ditambahkan'),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: AppColors.primaryGreen,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.lightGreen.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Category Filter
                Consumer<PosProvider>(
                  builder: (context, posProvider, child) {
                    return SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryChip('All', _selectedCategory == 'All'),
                          ...posProvider.categories
                              .map(
                                (category) => _buildCategoryChip(
                                  category.name,
                                  _selectedCategory == category.name,
                                ),
                              )
                              .toList(),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Product Grid
          Expanded(
            child: Consumer<PosProvider>(
              builder: (context, posProvider, child) {
                var filteredProducts = posProvider.products;

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  filteredProducts = filteredProducts.where((product) {
                    return product.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        (product.barcode?.contains(_searchQuery) ?? false);
                  }).toList();
                }

                // Apply category filter
                if (_selectedCategory != 'All') {
                  filteredProducts = filteredProducts
                      .where((p) => p.category == _selectedCategory)
                      .toList();
                }

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: AppColors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada produk',
                          style: TextStyle(fontSize: 18, color: AppColors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ProductGrid(
                  products: filteredProducts,
                  onProductTap: (product) {
                    if (product.stock <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} sudah habis'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    final maxQuantity = posProvider.getMaxQuantityForProduct(
                      product.id!,
                    );
                    if (maxQuantity <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${product.name} sudah mencapai batas maksimal di keranjang',
                          ),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    posProvider.addToCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${product.name} ditambahkan ke keranjang',
                        ),
                        backgroundColor: AppColors.primaryGreen,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                );
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

  void _showCartDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CartPanel(),
    );
  }
}
