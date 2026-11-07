import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/boleta.dart';

/// Modal para añadir un descuento a la boleta indicando:
/// 1. Nombre / motivo del descuento (ej. "Mi pago", "Pago del turno", etc.)
/// 2. Monto que se va a restar (ej. 20.00)
/// 3. Método del que se descuenta: Efectivo o Yape
class AddBoletaDiscountModal extends StatefulWidget {
  const AddBoletaDiscountModal({super.key});

  static Future<BoletaDescuento?> show(BuildContext context) {
    return showModalBottomSheet<BoletaDescuento>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddBoletaDiscountModal(),
    );
  }

  @override
  State<AddBoletaDiscountModal> createState() => _AddBoletaDiscountModalState();
}

class _AddBoletaDiscountModalState extends State<AddBoletaDiscountModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController =
      TextEditingController(text: '20.00');
  String _selectedMethod = 'Efectivo'; // 'Efectivo' o 'Yape'
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double get _currentAmount {
    final clean = _amountController.text.replaceAll(',', '.').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  void _submit() {
    final name = _nameController.text.trim();
    final amount = _currentAmount;

    if (name.isEmpty) {
      setState(() {
        _errorMessage =
            'Por favor escribe el nombre o motivo del descuento.';
      });
      return;
    }

    if (amount <= 0) {
      setState(() {
        _errorMessage = 'Por favor ingresa un monto mayor a S/. 0.00.';
      });
      return;
    }

    final discount = BoletaDescuento(
      id: 'desc_${DateTime.now().millisecondsSinceEpoch}',
      nombre: name,
      monto: double.parse(amount.toStringAsFixed(2)),
      metodoPago: _selectedMethod,
    );

    Navigator.pop(context, discount);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEfectivo = _selectedMethod == 'Efectivo';
    final isYape = _selectedMethod == 'Yape';

    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra superior de arrastre
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Cabecera
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: AppColors.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Añadir Descuento a la Boleta',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Se restará del total e indicará si fue en Efectivo o Yape',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 1. NOMBRE O DETALLE DEL DESCUENTO
              const Text(
                '1. NOMBRE O MOTIVO DEL DESCUENTO',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() => _errorMessage = null),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Ej. Pago del día, Mi turno, Adelanto...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13.5,
                  ),
                  prefixIcon: const Icon(
                    Icons.label_important_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Sugerencias rápidas de nombre
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Pago del día',
                  'Mi pago',
                  'Adelanto',
                  'Gasto extra',
                ].map((sugerencia) {
                  final isSelected =
                      _nameController.text.trim().toLowerCase() ==
                          sugerencia.toLowerCase();
                  return ActionChip(
                    backgroundColor: isSelected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.surfaceElevated,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.cardBorder,
                    ),
                    label: Text(
                      sugerencia,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _nameController.text = sugerencia;
                        _errorMessage = null;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // 2. MONTO A RESTAR
              const Text(
                '2. ¿CUÁNTO SE VA A RESTAR? (S/.)',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                onChanged: (_) => setState(() => _errorMessage = null),
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Text(
                      '- S/.',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  hintText: '20.00',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 18,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 50.0].map((val) {
                  final isSelected = (_currentAmount - val).abs() < 0.001;
                  return ActionChip(
                    backgroundColor: isSelected
                        ? AppColors.error.withValues(alpha: 0.2)
                        : AppColors.surfaceElevated,
                    side: BorderSide(
                      color:
                          isSelected ? AppColors.error : AppColors.cardBorder,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    label: Text(
                      '-${val.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _amountController.text = val.toStringAsFixed(2);
                        _errorMessage = null;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // 3. SELECCIONAR SI FUE EFECTIVO O YAPE
              const Text(
                '3. SELECCIONA SI FUE EN EFECTIVO O YAPE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          setState(() => _selectedMethod = 'Efectivo'),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isEfectivo
                              ? AppColors.efectivo.withValues(alpha: 0.2)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isEfectivo
                                ? AppColors.efectivo
                                : AppColors.cardBorder,
                            width: isEfectivo ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEfectivo
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              size: 18,
                              color: isEfectivo
                                  ? AppColors.efectivo
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.payments_rounded,
                              size: 18,
                              color: AppColors.efectivo,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Efectivo',
                              style: TextStyle(
                                color: isEfectivo
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMethod = 'Yape'),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isYape
                              ? AppColors.yape.withValues(alpha: 0.2)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                isYape ? AppColors.yape : AppColors.cardBorder,
                            width: isYape ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isYape
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              size: 18,
                              color: isYape
                                  ? AppColors.yape
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.qr_code_rounded,
                              size: 18,
                              color: AppColors.yape,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Yape',
                              style: TextStyle(
                                color: isYape
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
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

              // BOTÓN APLICAR DESCUENTO
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _submit,
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Aplicar descuento (-S/. ${_currentAmount.toStringAsFixed(2)} en $_selectedMethod)',
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

