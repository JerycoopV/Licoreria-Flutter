import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../repositories/sales_repository.dart';
import '../categories/categories_screen.dart';
import 'widgets/new_sale_button.dart';
import 'widgets/quick_metrics_bar.dart';
import 'widgets/sale_history_card.dart';

/// Pantalla Principal: Sencilla, limpia y enfocada en la rapidez de registro.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salesRepo = SalesRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.liquor_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('LICORERÍA POS'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Acerca del sistema',
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: ListenableBuilder(
            listenable: salesRepo,
            builder: (context, _) {
              final sales = salesRepo.sales;

              return CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 1. Barra de Métricas y Totales
                  SliverToBoxAdapter(
                    child: QuickMetricsBar(
                      grandTotal: salesRepo.totalSalesAmount,
                      cashTotal: salesRepo.totalCashAmount,
                      yapeTotal: salesRepo.totalYapeAmount,
                      count: sales.length,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // 2. BOTÓN GRANDE CON EL SÍMBOLO "+"
                  SliverToBoxAdapter(
                    child: NewSaleButton(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoriesScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 28)),

                  // 3. Encabezado del Historial
                  SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'HISTORIAL DE VENTAS',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        if (sales.isNotEmpty)
                          TextButton(
                            onPressed: () => _confirmClearHistory(context),
                            child: const Text(
                              'Limpiar',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // 4. LISTA DE REGISTROS DEBAJO DEL BOTÓN "+"
                  if (sales.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.cardBorder.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No hay registros anteriores',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Presiona el botón "+" para registrar tu primera venta',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final sale = sales[index];
                          return SaleHistoryCard(
                            sale: sale,
                            onDelete: () => salesRepo.removeSale(sale.id),
                          );
                        },
                        childCount: sales.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.liquor_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Licorería POS', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Estructura base y navegación inicial.\n\n'
          '• Registros con fecha y total.\n'
          '• Menú de 10 categorías con subcategorías para Cervezas.\n'
          '• Preparado para integración con base de datos local y listas de productos oficiales.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            child: const Text('Entendido',
                style: TextStyle(color: AppColors.primary)),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Limpiar historial?'),
        content: const Text(
          'Se eliminarán los registros actuales de prueba.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Limpiar', style: TextStyle(color: Colors.white)),
            onPressed: () {
              SalesRepository().clearAll();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
