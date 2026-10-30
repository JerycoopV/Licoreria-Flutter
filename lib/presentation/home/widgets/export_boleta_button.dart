import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/sale.dart';
import '../../../repositories/boletas_repository.dart';
import '../../boletas/boletas_screen.dart';
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
    final hasSales = sales.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    color: hasSales ? AppColors.primary : AppColors.textMuted,
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
      final boleta = BoletasRepository().buildBoletaFromSales(sales);

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
