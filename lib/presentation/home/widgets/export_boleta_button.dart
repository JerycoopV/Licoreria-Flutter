import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/sale.dart';
import '../../../repositories/boletas_repository.dart';
import '../../../repositories/sales_repository.dart';
import '../../boletas/boletas_screen.dart';
import 'add_boleta_discount_modal.dart';
import 'boleta_receipt_modal.dart';

/// Botón ubicado al inicio de la lista para exportar los productos registrados como una boleta con fecha actual.
class ExportBoletaButton extends StatelessWidget {
  final List<Sale> sales;

  const ExportBoletaButton({
    super.key,
    required this.sales,
  });

  @override
  Widget build(BuildContext context) {
    final boletasRepo = BoletasRepository();
    final salesRepo = SalesRepository();
    final hasSales = sales.isNotEmpty;
    final activeDiscounts = salesRepo.discounts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasSales
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.cardBorder,
              width: hasSales ? 1.4 : 1.0,
            ),
            boxShadow: hasSales
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleExportBoleta(context),
              borderRadius: BorderRadius.circular(16),
              splashColor: AppColors.primary.withValues(alpha: 0.15),
              highlightColor: AppColors.primary.withValues(alpha: 0.08),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Icono del botón
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: hasSales
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hasSales
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color:
                            hasSales ? AppColors.primary : AppColors.textMuted,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Título y subtítulo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'REVISAR BOLETA',
                                  style: TextStyle(
                                    color: hasSales
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (hasSales) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${sales.length}',
                                      style: const TextStyle(
                                        color: AppColors.primaryLight,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasSales
                                ? 'Guardar con fecha actual (${sales.length} prod.)'
                                : 'Registra productos para exportar boleta',
                            style: TextStyle(
                              color: hasSales
                                  ? AppColors.textSecondary
                                  : AppColors.textMuted,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Botón secundario para ir al listado de boletas
                    ListenableBuilder(
                      listenable: boletasRepo,
                      builder: (context, _) {
                        final count = boletasRepo.count;
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BoletasScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.folder_shared_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  count > 0 ? '$count' : 'Ver',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Botón para añadir descuento a la boleta desde la pantalla de registro
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            height: 42,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.45),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final discount = await AddBoletaDiscountModal.show(context);
                if (discount != null) {
                  await salesRepo.addDiscount(discount);
                }
              },
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                size: 18,
                color: AppColors.error,
              ),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Añadir descuento a la boleta',
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Lista de descuentos activos en la boleta actual
        if (activeDiscounts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: activeDiscounts.map((desc) {
                final methodColor =
                    desc.isYape ? AppColors.yape : AppColors.efectivo;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Descuento (${desc.nombre})',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: methodColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: methodColor.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Text(
                                desc.metodoPago,
                                style: TextStyle(
                                  color: methodColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '- S/. ${desc.monto.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => salesRepo.removeDiscount(desc.id),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Future<void> _handleExportBoleta(BuildContext context) async {
    if (sales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.warning, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No hay productos registrados para generar una boleta.',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    try {
      final boleta = BoletasRepository().buildBoletaFromSales(
        sales,
        descuentos: SalesRepository().discounts,
      );

      if (context.mounted) {
        // Mostrar el ticket visual con las opciones de Guardar o Limpiar boleta
        await BoletaReceiptModal.show(
          context,
          boleta: boleta,
          showClearOption: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text('Error al revisar boleta: $e'),
          ),
        );
      }
    }
  }
}
