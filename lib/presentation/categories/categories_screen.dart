import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../repositories/catalog_repository.dart';
import '../subcategories/subcategories_screen.dart';
import 'category_detail_screen.dart';
import 'widgets/category_tile.dart';
import 'widgets/product_card.dart';
import 'widgets/quick_sale_modal.dart';

/// Pantalla de Menú de Categorías con Buscador Global de Productos interactivo.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CatalogRepository _catalogRepo = CatalogRepository();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (!_catalogRepo.isLoaded) {
      _catalogRepo.loadProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = CatalogRepository.categories;
    final isWide = !ResponsiveLayout.isMobile(context);
    final isSearching = _searchQuery.trim().isNotEmpty;
    final searchResults =
        isSearching ? _catalogRepo.searchProducts(_searchQuery) : <Product>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú de Categorías'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          maxWidth: 800,
          child: CustomScrollView(
            slivers: [
              // 1. ENCABEZADO Y BUSCADOR GLOBAL DE PRODUCTOS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSearching
                            ? 'Resultados de Búsqueda'
                            : 'Selecciona una Categoría',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSearching
                            ? '${searchResults.length} ${searchResults.length == 1 ? "producto encontrado" : "productos encontrados"} para "$_searchQuery"'
                            : 'Elige una categoría o usa el buscador global para encontrar cualquier producto',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Buscador Global
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Buscar productos (ej. Inka, Pilsen, San Mateo...)',
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13.5,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      color: AppColors.textMuted, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: AppColors.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: AppColors.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. CONTENIDO: GRILLA DE CATEGORÍAS O RESULTADOS DE BÚSQUEDA GLOBAL
              if (!isSearching)
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 4 : 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: isWide ? 1.05 : 0.95,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = categories[index];
                        return CategoryTile(
                          category: category,
                          onTap: () => _handleCategoryTap(context, category),
                        );
                      },
                      childCount: categories.length,
                    ),
                  ),
                )
              else if (searchResults.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 48, horizontal: 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: const Icon(
                            Icons.search_off_rounded,
                            size: 44,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron productos para "$_searchQuery"',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Verifica que el nombre esté bien escrito o prueba con otra palabra clave como Inka, Pilsen, Halls...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          label: const Text('Limpiar búsqueda'),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 4 : 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: isWide ? 0.82 : 0.76,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = searchResults[index];
                        final cat = CatalogRepository.getCategoryById(
                                product.categoryId) ??
                            CatalogRepository.getCategoryById(
                                product.categoria);
                        final accentColor =
                            cat?.accentColor ?? AppColors.primary;
                        final fallbackIcon =
                            cat?.icon ?? Icons.local_bar_rounded;

                        return ProductCard(
                          product: product,
                          accentColor: accentColor,
                          fallbackIcon: fallbackIcon,
                          onTap: () => _handleProductTap(
                            product,
                            accentColor,
                            fallbackIcon,
                          ),
                        );
                      },
                      childCount: searchResults.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCategoryTap(BuildContext context, Category category) {
    if (category.hasSubcategories) {
      // Cervezas tiene subcategorías (Botellas y Latas)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubcategoriesScreen(category: category),
        ),
      );
    } else {
      // Categorías directas sin subcategorías
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryDetailScreen(category: category),
        ),
      );
    }
  }

  void _handleProductTap(
    Product product,
    Color accentColor,
    IconData fallbackIcon,
  ) async {
    final saleCompleted = await QuickSaleModal.show(
      context,
      product: product,
      accentColor: accentColor,
      fallbackIcon: fallbackIcon,
    );

    if (!mounted) return;
    if (saleCompleted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Venta de "${product.name}" registrada con éxito',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
