import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/sale.dart';

/// Tarjeta para mostrar cada registro de venta en el historial.
class SaleHistoryCard extends StatelessWidget {
  final Sale sale;
  final VoidCallback? onDelete;

  const SaleHistoryCard({
    super.key,
    required this.sale,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(sale.createdAt);

    Color methodColor;
    IconData methodIcon;

    switch (sale.paymentMethod) {
      case PaymentMethod.yape:
        methodColor = AppColors.yape;
        methodIcon = Icons.qr_code_rounded;
        break;
      case PaymentMethod.efectivo:
        methodColor = AppColors.efectivo;
        methodIcon = Icons.payments_rounded;
        break;
      case PaymentMethod.mixto:
        methodColor = AppColors.primary;
        methodIcon = Icons.swap_horiz_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Icono del método
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: methodColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(methodIcon, color: methodColor, size: 22),
          ),
          const SizedBox(width: 14),
          // Detalles: Fecha y Nota/Método
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: methodColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sale.paymentMethod.displayName,
                        style: TextStyle(
                          color: methodColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  sale.note ?? 'Registro de venta',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Monto Total
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'S/. ${sale.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 20, color: AppColors.textMuted),
              onPressed: onDelete,
              tooltip: 'Eliminar registro',
              splashRadius: 20,
            ),
          ],
        ],
      ),
    );
  }
}
