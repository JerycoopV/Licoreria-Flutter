import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../models/category.dart';
import '../../repositories/catalog_repository.dart';
import '../subcategories/subcategories_screen.dart';
import 'category_detail_screen.dart';
import 'widgets/category_tile.dart';

/// Pantalla de Menú de Categorías que se abre al pulsar el botón "+".
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = CatalogRepository.categories;
    final isWide = !ResponsiveLayout.isMobile(context);

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
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 20, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecciona una Categoría',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Elige una categoría para gestionar o registrar la venta',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
}
