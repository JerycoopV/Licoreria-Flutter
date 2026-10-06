import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/product.dart';
import '../../../models/sale.dart';
import '../../../repositories/sales_repository.dart';

/// Modal interactivo para seleccionar cantidad, método de pago y registrar la venta.
/// Cumple con las validaciones oficiales y persistencia offline.
class QuickSaleModal extends StatefulWidget {
  final Product product;
  final Color accentColor;
  final IconData fallbackIcon;

  const QuickSaleModal({
    super.key,
    required this.product,
    required this.accentColor,
    required this.fallbackIcon,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Product product,
    required Color accentColor,
    required IconData fallbackIcon,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickSaleModal(
        product: product,
        accentColor: accentColor,
        fallbackIcon: fallbackIcon,
      ),
    );
  }

  @override
  State<QuickSaleModal> createState() => _QuickSaleModalState();
}

class _QuickSaleModalState extends State<QuickSaleModal> {
  int _quantity = 1;
  String _selectedPaymentMethod = 'Efectivo'; // 'Efectivo' o 'Yape'
  bool _isProcessing = false;
  String? _validationError;

  double get _totalAmount => widget.product.precio * _quantity;

  void _increment() {
    setState(() {
      _quantity++;
      _validationError = null;
    });
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
        _validationError = null;
      });
    }
  }

  void _setQuantity(int qty) {
    if (qty >= 1) {
      setState(() {
        _quantity = qty;
        _validationError = null;
      });
    }
  }

  Future<void> _submitSale() async {
    // 1. Validaciones
    if (_quantity <= 0) {
      setState(() {
        _validationError = 'La cantidad debe ser un número entero positivo';
      });
      return;
    }

    if (widget.product.precio < 0) {
      setState(() {
        _validationError = 'El precio del producto debe ser válido';
      });
      return;
    }

    if (_selectedPaymentMethod.trim().isEmpty) {
      setState(() {
        _validationError = 'Selecciona un método de pago';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _validationError = null;
    });

    try {
      // 2. Crear el registro de venta con los campos oficiales
      final newSale = Sale(
        id: DateTime.now().millisecondsSinceEpoch,
        nombre: widget.product.nombre,
        categoria: widget.product.categoria,
        cantidad: _quantity,
        precio: widget.product.precio, // PRECIO UNITARIO
        metodoPago: _selectedPaymentMethod, // "Efectivo" o "Yape"
        createdAt: DateTime.now(),
      );

      // 3. Guardar en almacenamiento local offline y actualizar historial
      final success = await SalesRepository().recordSale(newSale);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _isProcessing = false;
          _validationError =
              'Ocurrió un error al guardar la venta en el almacenamiento local.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _validationError = 'Error inesperado: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasImage = widget.product.image != null &&
        widget.product.image!.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 24 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Píldora decorativa
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Encabezado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Registrar Venta',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Información del Producto
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasImage
                        ? Image.asset(
                            widget.product.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Icon(
                              widget.fallbackIcon,
                              color: widget.accentColor,
                              size: 28,
                            ),
                          )
                        : Icon(
                            widget.fallbackIcon,
                            color: widget.accentColor,
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.nombre,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    widget.accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.product.categoria,
                                style: TextStyle(
                                  color: widget.accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Precio: S/. ${widget.product.precio.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
            const SizedBox(height: 18),

            // Selector de Cantidad
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CANTIDAD',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: [1, 2, 3, 6, 12].map((val) {
                    final isSelected = _quantity == val;
                    return InkWell(
                      onTap: () => _setQuantity(val),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.accentColor.withValues(alpha: 0.25)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? widget.accentColor
                                : AppColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          '$val',
                          style: TextStyle(
                            color: isSelected
                                ? widget.accentColor
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Controles [-] Cantidad [+]
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _quantity > 1 ? _decrement : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: _quantity > 1
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    iconSize: 28,
                  ),
                  Column(
                    children: [
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'unidades',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _increment,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: widget.accentColor,
                    iconSize: 28,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Total Calculado (cantidad × precio)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL A COBRAR',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        '$_quantity × S/. ${widget.product.precio.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'S/. ${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // MÉTODO DE PAGO (Efectivo / Yape)
            const Text(
              'MÉTODO DE PAGO',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                // Opción Efectivo
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = 'Efectivo';
                        _validationError = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _selectedPaymentMethod == 'Efectivo'
                            ? AppColors.efectivo.withValues(alpha: 0.15)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedPaymentMethod == 'Efectivo'
                              ? AppColors.efectivo
                              : AppColors.cardBorder,
                          width: _selectedPaymentMethod == 'Efectivo' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedPaymentMethod == 'Efectivo'
                                    ? AppColors.efectivo
                                    : AppColors.textMuted,
                                width: 2,
                              ),
                            ),
                            child: _selectedPaymentMethod == 'Efectivo'
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.efectivo,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const Icon(Icons.payments_rounded,
                              color: AppColors.efectivo, size: 20),
                          const SizedBox(width: 6),
                          const Text(
                            'Efectivo',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Opción Yape
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = 'Yape';
                        _validationError = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _selectedPaymentMethod == 'Yape'
                            ? AppColors.yape.withValues(alpha: 0.15)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedPaymentMethod == 'Yape'
                              ? AppColors.yape
                              : AppColors.cardBorder,
                          width: _selectedPaymentMethod == 'Yape' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedPaymentMethod == 'Yape'
                                    ? AppColors.yape
                                    : AppColors.textMuted,
                                width: 2,
                              ),
                            ),
                            child: _selectedPaymentMethod == 'Yape'
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.yape,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const Icon(Icons.qr_code_rounded,
                              color: AppColors.yape, size: 20),
                          const SizedBox(width: 6),
                          const Text(
                            'Yape',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_validationError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 22),

            // BOTÓN: "Registrar venta"
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 22),
              label: Text(
                _isProcessing
                  ? 'Guardando...'
                  : 'Registrar venta (S/. ${_totalAmount.toStringAsFixed(2)})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: _isProcessing ? null : _submitSale,
            ),
          ],
        ),
      ),
    );
  }
}
