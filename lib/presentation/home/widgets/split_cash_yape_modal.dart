import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/sale.dart';
import '../../../repositories/sales_repository.dart';

/// Modal interactivo para ventas en Efectivo que permite elegir la opción
/// "Dividir precio con Yape" e indicar cuánto se pagó en Efectivo y cuánto en Yape.
class SplitCashYapeModal extends StatefulWidget {
  final Sale sale;

  const SplitCashYapeModal({
    super.key,
    required this.sale,
  });

  static Future<bool?> show(BuildContext context, {required Sale sale}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SplitCashYapeModal(sale: sale),
    );
  }

  @override
  State<SplitCashYapeModal> createState() => _SplitCashYapeModalState();
}

class _SplitCashYapeModalState extends State<SplitCashYapeModal> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  late final TextEditingController _cashController;
  late final TextEditingController _yapeController;

  bool _showSplitForm = false;
  bool _isProcessing = false;
  bool _isUpdatingFields = false;
  double _cashValue = 0.0;
  double _yapeValue = 0.0;

  double get _total => widget.sale.total;

  @override
  void initState() {
    super.initState();
    if (widget.sale.isSplitPayment) {
      _showSplitForm = true;
      _cashValue = widget.sale.cashAmount;
      _yapeValue = widget.sale.yapeAmount;
    } else {
      // Por defecto sugerir mitad y mitad al abrir la opción de dividir
      _cashValue = double.parse((_total / 2).toStringAsFixed(2));
      _yapeValue = double.parse((_total - _cashValue).toStringAsFixed(2));
    }

    _cashController = TextEditingController(
      text: _cashValue.toStringAsFixed(2),
    );
    _yapeController = TextEditingController(
      text: _yapeValue.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    _yapeController.dispose();
    super.dispose();
  }

  void _onCashChanged(String val) {
    if (_isUpdatingFields) return;
    _isUpdatingFields = true;

    final parsed = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
    final clampedCash = parsed.clamp(0.0, _total);
    final remainingYape =
        double.parse((_total - clampedCash).toStringAsFixed(2));

    setState(() {
      _cashValue = clampedCash;
      _yapeValue = remainingYape;
      _yapeController.text = remainingYape.toStringAsFixed(2);
    });

    _isUpdatingFields = false;
  }

  void _onYapeChanged(String val) {
    if (_isUpdatingFields) return;
    _isUpdatingFields = true;

    final parsed = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
    final clampedYape = parsed.clamp(0.0, _total);
    final remainingCash =
        double.parse((_total - clampedYape).toStringAsFixed(2));

    setState(() {
      _yapeValue = clampedYape;
      _cashValue = remainingCash;
      _cashController.text = remainingCash.toStringAsFixed(2);
    });

    _isUpdatingFields = false;
  }

  void _applyHalfSplit() {
    _isUpdatingFields = true;
    final half = double.parse((_total / 2).toStringAsFixed(2));
    final otherHalf = double.parse((_total - half).toStringAsFixed(2));

    setState(() {
      _cashValue = half;
      _yapeValue = otherHalf;
      _cashController.text = half.toStringAsFixed(2);
      _yapeController.text = otherHalf.toStringAsFixed(2);
    });
    _isUpdatingFields = false;
  }

  bool get _isValidSplit {
    final sum = _cashValue + _yapeValue;
    return _cashValue > 0 &&
        _yapeValue > 0 &&
        (sum - _total).abs() <= 0.05;
  }

  @override
  Widget build(BuildContext context) {
    final salesRepo = SalesRepository();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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

            // Encabezado estilo CombineYapeModal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.efectivo.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: AppColors.efectivo,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pago en Efectivo',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Configura o divide el pago de este producto',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Venta Seleccionada
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.efectivo.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.efectivo.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'VENTA SELECCIONADA',
                          style: TextStyle(
                            color: AppColors.efectivo,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        _dateFormat.format(widget.sale.createdAt),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.sale.nombre,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'S/. ${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.efectivo,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (widget.sale.isSplitPayment) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Actual: Efectivo S/. ${widget.sale.cashAmount.toStringAsFixed(2)}  •  Yape S/. ${widget.sale.yapeAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Opción: "Dividir precio con yape"
            const Text(
              'OPCIONES DE PAGO',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),

            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showSplitForm = !_showSplitForm;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: _showSplitForm
                        ? AppColors.yape.withValues(alpha: 0.14)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _showSplitForm
                          ? AppColors.yape
                          : AppColors.cardBorder,
                      width: _showSplitForm ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.yape.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.call_split_rounded,
                          color: AppColors.yape,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dividir precio con yape',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Elige cuánto pagó en Efectivo y cuánto en Yape',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _showSplitForm
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.yape,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Formulario de división de montos cuando el usuario toca "Dividir precio con yape"
            if (_showSplitForm) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ingresa los montos:',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        InkWell(
                          onTap: _applyHalfSplit,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'Mitad y mitad (50/50)',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Campo Efectivo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.payments_rounded,
                                      size: 14, color: AppColors.efectivo),
                                  SizedBox(width: 4),
                                  Text(
                                    'En Efectivo',
                                    style: TextStyle(
                                      color: AppColors.efectivo,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _cashController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: _onCashChanged,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                                decoration: InputDecoration(
                                  prefixText: 'S/. ',
                                  prefixStyle: const TextStyle(
                                    color: AppColors.efectivo,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: AppColors.efectivo
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppColors.efectivo,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Campo Yape
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.qr_code_rounded,
                                      size: 14, color: AppColors.yape),
                                  SizedBox(width: 4),
                                  Text(
                                    'En Yape',
                                    style: TextStyle(
                                      color: AppColors.yape,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _yapeController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: _onYapeChanged,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                                decoration: InputDecoration(
                                  prefixText: 'S/. ',
                                  prefixStyle: const TextStyle(
                                    color: AppColors.yape,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color:
                                          AppColors.yape.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppColors.yape,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Resumen del desglose
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Efectivo: S/. ${_cashValue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.efectivo,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            '+',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Yape: S/. ${_yapeValue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.yape,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            '=',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'S/. ${(_cashValue + _yapeValue).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Botón para Guardar la división
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.efectivo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  disabledBackgroundColor: AppColors.surfaceElevated,
                  disabledForegroundColor: AppColors.textMuted,
                ),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _isValidSplit
                      ? 'Guardar división (Efectivo S/. ${_cashValue.toStringAsFixed(2)} + Yape S/. ${_yapeValue.toStringAsFixed(2)})'
                      : 'Ingresa montos válidos para dividir',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: (!_isValidSplit || _isProcessing)
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        setState(() => _isProcessing = true);
                        final success = await salesRepo.splitSaleWithYape(
                          saleId: widget.sale.id,
                          cashAmount: _cashValue,
                          yapeAmount: _yapeValue,
                        );
                        if (!mounted) return;
                        setState(() => _isProcessing = false);
                        if (success) {
                          navigator.pop(true);
                        }
                      },
              ),
            ],

            if (widget.sale.isSplitPayment) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text(
                  'Restaurar todo a Efectivo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: _isProcessing
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        setState(() => _isProcessing = true);
                        final success = await salesRepo
                            .restoreSplitSaleToCash(widget.sale.id);
                        if (!mounted) return;
                        setState(() => _isProcessing = false);
                        if (success) {
                          navigator.pop(true);
                        }
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

