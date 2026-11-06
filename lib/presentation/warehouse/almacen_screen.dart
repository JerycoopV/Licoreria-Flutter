import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../repositories/catalog_repository.dart';
import '../categories/widgets/product_card.dart';
import '../categories/widgets/quick_sale_modal.dart';
import 'widgets/add_product_modal.dart';

/// Pantalla de Almacén: Muestra la lista completa de todos los productos
/// dividida y organizada por categorías, con opción para añadir nuevos productos.
class AlmacenScreen extends StatefulWidget {
  const AlmacenScreen({super.key});

  @override
  State<AlmacenScreen> createState() => _AlmacenScreenState();
}

class _AlmacenScreenState extends State<AlmacenScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CatalogRepository _catalogRepo = CatalogRepository();
  String _searchQuery = '';
  String? _selectedCategoryId;

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

  List<Product> _filterCategoryProducts(Category category) {
    final products = _catalogRepo.getProductsByCategory(category.id);
    if (_searchQuery.trim().isEmpty) {
      return products;
    }
    final searched = _catalogRepo.searchProducts(
      _searchQuery,
      categoryId: category.id,
    );
    return searched;
  }

  void _openAddProductModal() async {
    final addedProduct = await AddProductModal.show(
      context,
      initialCategoryId: _selectedCategoryId,
    );

    if (!mounted || addedProduct == null) return;

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
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Producto "${addedProduct.nombre}" añadido a ${addedProduct.categoria}',
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
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Venta de "${product.name}" registrada en Boleta',
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

  @override
  Widget build(BuildContext context) {
    final isWide = !ResponsiveLayout.isMobile(context);
    final allCategories = CatalogRepository.categories;

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_rounded,
                color: Color(0xFF4368C7),
                size: 22,
              ),
              SizedBox(width: 8),
              Text('ALMACÉN DE PRODUCTOS'),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Añadir nuevo producto',
            icon: const Icon(
              Icons.add_box_rounded,
              color: AppColors.primary,
            ),
            onPressed: _openAddProductModal,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          maxWidth: 900,
          child: ListenableBuilder(
            listenable: _catalogRepo,
            builder: (context, _) {
              if (_catalogRepo.isLoading && !_catalogRepo.isLoaded) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final visibleCategories = _selectedCategoryId == null
                  ? allCategories
                  : allCategories
                      .where((c) => c.id == _selectedCategoryId)
                      .toList();

              // Construir los bloques por categoría que tengan productos
              final categorySections = <_CategorySectionData>[];
              int totalMatchingProducts = 0;

              for (final category in visibleCategories) {
                final products = _filterCategoryProducts(category);
                if (products.isNotEmpty) {
                  categorySections.add(
                    _CategorySectionData(
                      category: category,
                      products: products,
                    ),
                  );
                  totalMatchingProducts += products.length;
                }
              }

              return CustomScrollView(
                slivers: [
                  // 1. RESUMEN, BOTÓN AÑADIR PRODUCTO Y BUSCADOR DE ALMACÉN
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Banner superior del Almacén con botón "+ Añadir Producto"
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4368C7)
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.warehouse_rounded,
                                    color: Color(0xFF6085E8),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Catálogo General del Almacén',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$totalMatchingProducts ${totalMatchingProducts == 1 ? "producto" : "productos"} en ${categorySections.length} ${categorySections.length == 1 ? "categoría" : "categorías"}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 11,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _openAddProductModal,
                                  icon: const Icon(Icons.add_rounded, size: 19),
                                  label: const Text(
                                    'Añadir Producto',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Buscador de productos
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
                                  'Buscar en el almacén (ej. Pilsen, Smirnoff, Hielo...)',
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
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        color: AppColors.textMuted,
                                        size: 18,
                                      ),
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
                                vertical: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: AppColors.cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: AppColors.cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Filtro de todas las categorías visibles
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _CategoryFilterChip(
                                label: 'Todas (${allCategories.length})',
                                icon: Icons.grid_view_rounded,
                                color: AppColors.primary,
                                isSelected: _selectedCategoryId == null,
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryId = null;
                                  });
                                },
                              ),
                              ...allCategories.map((cat) {
                                final color =
                                    cat.accentColor ?? AppColors.primary;
                                final isSelected =
                                    _selectedCategoryId == cat.id;
                                return _CategoryFilterChip(
                                  label: cat.name,
                                  icon: cat.icon,
                                  color: color,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategoryId =
                                          isSelected ? null : cat.id;
                                    });
                                  },
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. LISTADO DE PRODUCTOS DIVIDIDO POR CATEGORÍAS
                  if (categorySections.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 48,
                          horizontal: 24,
                        ),
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
                                size: 42,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No se encontraron productos',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Intenta con otro nombre o selecciona "Todas" las categorías.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    for (final section in categorySections) ...[
                      // Cabecera de la Categoría
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 12),
                          child: _CategorySectionHeader(
                            category: section.category,
                            productCount: section.products.length,
                          ),
                        ),
                      ),

                      // Grilla de productos de esta Categoría
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 12),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isWide ? 4 : 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: isWide ? 0.82 : 0.76,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = section.products[index];
                              final accentColor =
                                  section.category.accentColor ??
                                      AppColors.primary;
                              return ProductCard(
                                product: product,
                                accentColor: accentColor,
                                fallbackIcon: section.category.icon,
                                onTap: () => _handleProductTap(
                                  product,
                                  accentColor,
                                  section.category.icon,
                                ),
                              );
                            },
                            childCount: section.products.length,
                          ),
                        ),
                      ),
                    ],

                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CategorySectionData {
  final Category category;
  final List<Product> products;

  const _CategorySectionData({
    required this.category,
    required this.products,
  });
}

class _CategorySectionHeader extends StatelessWidget {
  final Category category;
  final int productCount;

  const _CategorySectionHeader({
    required this.category,
    required this.productCount,
  });

  @override
  Widget build(BuildContext context) {
    final color = category.accentColor ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              category.icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Text(
              '$productCount ${productCount == 1 ? "producto" : "productos"}',
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.22) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : AppColors.cardBorder,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? color : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
