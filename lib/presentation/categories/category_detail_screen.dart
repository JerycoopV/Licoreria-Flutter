import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../models/category.dart';
import '../../models/sale.dart';
import '../../repositories/sales_repository.dart';

/// Pantalla contenedora de productos por categoría.
/// Respeta la regla: NO productos inventados. Muestra el estado limpio
/// y preparado para recibir las listas oficiales del usuario.
class CategoryDetailScreen extends StatelessWidget {
  final Category category;
  final Subcategory? subcategory;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    this.subcategory,
  });

  @override
  Widget build(BuildContext context) {
    final color = category.accentColor ?? AppColors.primary;
    final title = subcategory != null
        ? '${category.name} - ${subcategory!.name}'
        : category.name;

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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            subcategory?.icon ?? category.icon,
                            size: 44,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 18, color: color),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Estructura lista para tus productos',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Aún no se han cargado productos en esta categoría. En la siguiente etapa se incorporarán los nombres y precios oficiales proporcionados.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Botón para probar la integración con el historial de ventas
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '¿Deseas probar el registro de una venta con esta categoría?',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.efectivo,
                                side: const BorderSide(color: AppColors.efectivo),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.payments_rounded, size: 18),
                              label: const Text('Efectivo (S/. 30)'),
                              onPressed: () => _registerTestSale(
                                context,
                                paymentMethod: PaymentMethod.efectivo,
                                amount: 30.00,
                                title: title,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.yape,
                                side: const BorderSide(color: AppColors.yape),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.qr_code_rounded, size: 18),
                              label: const Text('Yape (S/. 30)'),
                              onPressed: () => _registerTestSale(
                                context,
                                paymentMethod: PaymentMethod.yape,
                                amount: 30.00,
                                title: title,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _registerTestSale(
    BuildContext context, {
    required PaymentMethod paymentMethod,
    required double amount,
    required String title,
  }) {
    final newSale = Sale(
      id: 'sale_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      totalAmount: amount,
      cashAmount: paymentMethod == PaymentMethod.efectivo ? amount : 0.0,
      yapeAmount: paymentMethod == PaymentMethod.yape ? amount : 0.0,
      paymentMethod: paymentMethod,
      note: 'Venta registrada en $title',
    );

    SalesRepository().recordSale(newSale);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text(
          'Venta de S/. ${amount.toStringAsFixed(2)} registrada exitosamente',
          style: const TextStyle(color: AppColors.textPrimary),
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
