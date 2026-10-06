import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../repositories/catalog_repository.dart';
import 'widgets/product_card.dart';
import 'widgets/quick_sale_modal.dart';

/// Pantalla detallada de productos para la categoría o subcategoría seleccionada.
/// Presenta grilla interactiva, búsqueda en tiempo real y registro rápido de ventas.
class CategoryDetailScreen extends StatefulWidget {
  final Category category;
  final Subcategory? subcategory;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    this.subcategory,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CatalogRepository _catalogRepo = CatalogRepository();

  String? _selectedSubcategoryId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedSubcategoryId = widget.subcategory?.id;
    // Si aún no está cargado el catálogo, cargarlo
    if (!_catalogRepo.isLoaded) {
      _catalogRepo.loadProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _getFilteredProducts() {
    List<Product> list = _catalogRepo.getProductsByCategory(
      widget.category.id,
      subcategoryId: _selectedSubcategoryId,
    );

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      list = list.where((p) => p.name.toLowerCase().contains(query)).toList();
    }

    return list;
  }

  void _onProductTap(Product product) async {
    final color = widget.category.accentColor ?? AppColors.primary;
    final fallbackIcon = widget.subcategory?.icon ?? widget.category.icon;

    final saleCompleted = await QuickSaleModal.show(
      context,
      product: product,
      accentColor: color,
      fallbackIcon: fallbackIcon,
    );

    if (saleCompleted == true && mounted) {
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
          action: SnackBarAction(
            label: 'Ir al Inicio',
            textColor: AppColors.primary,
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.category.accentColor ?? AppColors.primary;
    final isWide = !ResponsiveLayout.isMobile(context);

    final title = widget.subcategory != null
        ? '${widget.category.name} - ${widget.subcategory!.name}'
        : widget.category.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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

              if (_catalogRepo.hasError && !_catalogRepo.isLoaded) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            size: 52, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          _catalogRepo.errorMessage ??
                              'No se pudo cargar el catálogo de productos.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reintentar'),
                          onPressed: () =>
                              _catalogRepo.loadProducts(forceRefresh: true),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final products = _getFilteredProducts();

              return Column(
                children: [
                  // 1. BANNER CABECERA DE CATEGORÍA
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Container(
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
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              widget.subcategory?.icon ?? widget.category.icon,
                              color: color,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${products.length} ${products.length == 1 ? "producto disponible" : "productos disponibles"}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. FILTRO POR SUBCATEGORÍAS (Si la categoría contiene subcategorías y no se fijó una de antemano)
                  if (widget.category.hasSubcategories &&
                      widget.subcategory == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Todos'),
                              selected: _selectedSubcategoryId == null,
                              selectedColor: color.withValues(alpha: 0.25),
                              backgroundColor: AppColors.surface,
                              side: BorderSide(
                                color: _selectedSubcategoryId == null
                                    ? color
                                    : AppColors.cardBorder,
                              ),
                              labelStyle: TextStyle(
                                color: _selectedSubcategoryId == null
                                    ? color
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedSubcategoryId = null;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ...widget.category.subcategories.map((sub) {
                              final isSelected =
                                  _selectedSubcategoryId == sub.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  avatar: Icon(sub.icon,
                                      size: 16,
                                      color: isSelected
                                          ? color
                                          : AppColors.textSecondary),
                                  label: Text(sub.name),
                                  selected: isSelected,
                                  selectedColor: color.withValues(alpha: 0.25),
                                  backgroundColor: AppColors.surface,
                                  side: BorderSide(
                                    color: isSelected
                                        ? color
                                        : AppColors.cardBorder,
                                  ),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? color
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedSubcategoryId = sub.id;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                  // 3. BARRA DE BÚSQUEDA RÁPIDA DE PRODUCTOS
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar en ${widget.category.name}...',
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13.5,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted,
                          size: 20,
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: color, width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  // 4. GRILLA DE PRODUCTOS O ESTADO VACÍO
                  Expanded(
                    child: products.isEmpty
                        ? _buildEmptyState(color)
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isWide ? 4 : 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: isWide ? 0.82 : 0.76,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return ProductCard(
                                product: product,
                                accentColor: color,
                                fallbackIcon: widget.subcategory?.icon ??
                                    widget.category.icon,
                                onTap: () => _onProductTap(product),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 36,
                color: color,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Sin resultados para "$_searchQuery"'
                  : 'No hay productos disponibles',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Verifica la escritura o prueba con otro término de búsqueda.'
                  : 'Agrega productos a esta categoría en assets/data/products.json.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.backspace_outlined, size: 16),
                label: const Text('Limpiar búsqueda'),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
