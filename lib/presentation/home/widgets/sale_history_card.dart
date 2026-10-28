import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/sale.dart';

/// Tarjeta para mostrar cada registro de venta en el historial.
/// Muestra nombre del producto, categoría, cantidad, precio unitario y total.
class SaleHistoryCard extends StatelessWidget {
  final Sale sale;
  final VoidCallback? onDelete;
  final VoidCallback? onCombine;
  final VoidCallback? onTap;

  const SaleHistoryCard({
    super.key,
    required this.sale,
    this.onDelete,
    this.onCombine,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final formattedDate = dateFormat.format(sale.createdAt);

    Color methodColor;
    IconData methodIcon;

    final isYape = sale.metodoPago.toLowerCase() == 'yape';
    if (isYape) {
      methodColor = AppColors.yape;
      methodIcon = Icons.qr_code_rounded;
    } else {
      methodColor = AppColors.efectivo;
      methodIcon = Icons.payments_rounded;
    }

    final VoidCallback? effectiveTap = isYape ? onCombine : onTap;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: effectiveTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: methodColor.withValues(alpha: 0.15),
          highlightColor: methodColor.withValues(alpha: 0.08),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: sale.isCombined
                    ? AppColors.yape.withValues(alpha: 0.5)
                    : AppColors.cardBorder,
                width: sale.isCombined ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icono del método
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: methodColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(methodIcon, color: methodColor, size: 20),
                ),
                const SizedBox(width: 10),
                // Detalles: Nombre, Categoría, Cantidad y Precio Unitario
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: methodColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sale.metodoPago,
                              style: TextStyle(
                                color: methodColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (sale.isCombined)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.yape.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.yape.withValues(alpha: 0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.call_merge_rounded,
                                    size: 10,
                                    color: AppColors.yape,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'COMBINADO',
                                    style: TextStyle(
                                      color: AppColors.yape,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sale.nombre,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sale.isCombined
                            ? '${sale.categoria}  •  ${sale.originalSales.isNotEmpty ? "${sale.originalSales.length} ventas unificadas" : "${sale.items.length} productos"}'
                            : '${sale.categoria}  •  ${sale.cantidad} x S/. ${sale.precio.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: sale.isCombined
                              ? AppColors.yape.withValues(alpha: 0.9)
                              : AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: sale.isCombined
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Columna derecha: Monto Total y Botones de acción compactos
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'S/. ${sale.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isYape && onCombine != null)
                          InkWell(
                            onTap: onCombine,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                sale.isCombined
                                    ? Icons.layers_rounded
                                    : Icons.call_merge_rounded,
                                size: 17,
                                color: AppColors.yape,
                              ),
                            ),
                          ),
                        if (onDelete != null) ...[
                          if (isYape && onCombine != null)
                            const SizedBox(width: 4),
                          InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 17,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
