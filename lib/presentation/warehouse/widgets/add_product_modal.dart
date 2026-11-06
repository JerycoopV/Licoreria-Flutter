import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/image_picker_helper.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../repositories/catalog_repository.dart';

/// Modal interactivo en el Almacén para añadir un nuevo producto:
/// 1. Escoger la categoría (y subcategoría si aplica)
/// 2. Escribir el nombre del producto
/// 3. Escoger el precio
/// 4. Subir la imagen del producto
class AddProductModal extends StatefulWidget {
  final String? initialCategoryId;

  const AddProductModal({
    super.key,
    this.initialCategoryId,
  });

  static Future<Product?> show(
    BuildContext context, {
    String? initialCategoryId,
  }) {
    return showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddProductModal(
        initialCategoryId: initialCategoryId,
      ),
    );
  }

  @override
  State<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  late Category _selectedCategory;
  String? _selectedSubcategoryId;
  String? _uploadedImageDataUrl;
  String? _errorMessage;
  bool _isSaving = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    final categories = CatalogRepository.categories;
    _selectedCategory = categories.firstWhere(
      (c) => c.id == widget.initialCategoryId,
      orElse: () => categories.first,
    );
    if (_selectedCategory.hasSubcategories) {
      _selectedSubcategoryId = _selectedCategory.subcategories.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  double get _currentPrice {
    final clean = _priceController.text.replaceAll(',', '.').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  void _adjustPrice(double delta) {
    final next = (_currentPrice + delta).clamp(0.0, 9999.0);
    setState(() {
      _priceController.text = next.toStringAsFixed(2);
      _errorMessage = null;
    });
  }

  void _setPresetPrice(double price) {
    setState(() {
      _priceController.text = price.toStringAsFixed(2);
      _errorMessage = null;
    });
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() {
      _isPickingImage = true;
      _errorMessage = null;
    });

    try {
      final dataUrl = await ImagePickerHelper.pickImageAsDataUrl();
      if (!mounted) return;
      if (dataUrl != null && dataUrl.isNotEmpty) {
        setState(() {
          _uploadedImageDataUrl = dataUrl;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final price = _currentPrice;

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor escribe el nombre del producto.';
      });
      return;
    }

    if (price <= 0) {
      setState(() {
        _errorMessage = 'Por favor ingresa o escoge un precio mayor a S/. 0.00.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final newProduct = Product(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      nombre: name,
      categoria: _selectedCategory.name,
      precio: double.parse(price.toStringAsFixed(2)),
      image: _uploadedImageDataUrl,
      subcategoryId:
          _selectedCategory.hasSubcategories ? _selectedSubcategoryId : null,
      isAvailable: true,
    );

    await CatalogRepository().addCustomProduct(newProduct);

    if (!mounted) return;
    Navigator.pop(context, newProduct);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final categories = CatalogRepository.categories;
    final accentColor = _selectedCategory.accentColor ?? AppColors.primary;
    final previewBytes =
        ImagePickerHelper.decodeDataUrl(_uploadedImageDataUrl);

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
              // Indicador superior de arrastre
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

              // Cabecera del modal
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_box_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Añadir Nuevo Producto',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Se guardará directamente en tu Almacén',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
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

              // ============================================================
              // PASO 1: ESCOGER LA CATEGORÍA (TODAS LAS 14 CATEGORÍAS VISIBLES)
              // ============================================================
              _StepLabel(
                stepNumber: '1',
                title: 'ESCOGE LA CATEGORÍA (${categories.length} DISPONIBLES)',
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 480 ? 4 : 3;
                  final spacing = 8.0;
                  final itemWidth =
                      (constraints.maxWidth - (spacing * (columns - 1))) /
                          columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: categories.map((cat) {
                      final isSelected = cat.id == _selectedCategory.id;
                      final catColor = cat.accentColor ?? AppColors.primary;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                            _selectedSubcategoryId = cat.hasSubcategories
                                ? cat.subcategories.first.id
                                : null;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: itemWidth,
                          constraints: const BoxConstraints(minHeight: 68),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? catColor.withValues(alpha: 0.22)
                                : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected ? catColor : AppColors.cardBorder,
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                cat.icon,
                                color: isSelected
                                    ? catColor
                                    : AppColors.textSecondary,
                                size: 22,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                cat.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              // Subcategorías si la categoría seleccionada tiene (ej. Cervezas: Botellas / Latas)
              if (_selectedCategory.hasSubcategories) ...[
                const SizedBox(height: 12),
                Row(
                  children: _selectedCategory.subcategories.map((sub) {
                    final isSubSelected = _selectedSubcategoryId == sub.id;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          avatar: Icon(
                            sub.icon,
                            size: 16,
                            color: isSubSelected
                                ? accentColor
                                : AppColors.textSecondary,
                          ),
                          label: Text(sub.name),
                          selected: isSubSelected,
                          selectedColor: accentColor.withValues(alpha: 0.22),
                          backgroundColor: AppColors.surfaceElevated,
                          side: BorderSide(
                            color: isSubSelected
                                ? accentColor
                                : AppColors.cardBorder,
                          ),
                          labelStyle: TextStyle(
                            color: isSubSelected
                                ? accentColor
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedSubcategoryId = sub.id;
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),

              // ============================================================
              // PASO 2: ESCRIBIR EL NOMBRE DEL PRODUCTO
              // ============================================================
              const _StepLabel(
                stepNumber: '2',
                title: 'ESCRIBE EL NOMBRE DEL PRODUCTO',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Ej. Six Pack Pilsen Lata 355ml',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13.5,
                  ),
                  prefixIcon: Icon(
                    _selectedCategory.icon,
                    color: accentColor,
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
                    borderSide: BorderSide(color: accentColor, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ============================================================
              // PASO 3: ESCOGER EL PRECIO
              // ============================================================
              const _StepLabel(
                stepNumber: '3',
                title: 'ESCOGE O ESCRIBE EL PRECIO (S/.)',
              ),
              const SizedBox(height: 8),

              // Campo principal de precio a ancho completo para móviles
              TextField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Text(
                      'S/.',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  hintText: '0.00',
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
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Fila de 4 botones de ajuste rápido (-1.00, -0.50, +0.50, +1.00)
              Row(
                children: [
                  Expanded(
                    child: _PriceAdjustButton(
                      label: '-1.00',
                      onTap: () => _adjustPrice(-1.0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PriceAdjustButton(
                      label: '-0.50',
                      onTap: () => _adjustPrice(-0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PriceAdjustButton(
                      label: '+0.50',
                      isPositive: true,
                      onTap: () => _adjustPrice(0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PriceAdjustButton(
                      label: '+1.00',
                      isPositive: true,
                      onTap: () => _adjustPrice(1.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Botones rápidos de precios frecuentes
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [2.0, 5.0, 8.0, 10.0, 15.0, 20.0, 28.0, 35.0]
                    .map((preset) {
                  return ActionChip(
                    backgroundColor: AppColors.surfaceElevated,
                    side: const BorderSide(color: AppColors.cardBorder),
                    label: Text(
                      'S/. ${preset.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => _setPresetPrice(preset),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ============================================================
              // PASO 4: SUBIR LA IMAGEN DEL PRODUCTO
              // ============================================================
              const _StepLabel(
                stepNumber: '4',
                title: 'SUBE LA IMAGEN DEL PRODUCTO (OPCIONAL)',
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: previewBytes != null
                          ? AppColors.success.withValues(alpha: 0.6)
                          : AppColors.cardBorder,
                      width: 1.2,
                    ),
                  ),
                  child: previewBytes != null
                      ? Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                previewBytes,
                                width: 68,
                                height: 68,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.success,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Imagen cargada',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Toca para cambiar por otra imagen',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Quitar imagen',
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                              ),
                              onPressed: () {
                                setState(() {
                                  _uploadedImageDataUrl = null;
                                });
                              },
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: _isPickingImage
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: accentColor,
                                      ),
                                    )
                                  : Icon(
                                      Icons.add_photo_alternate_rounded,
                                      color: accentColor,
                                      size: 24,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            const Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Toca aquí para subir una imagen',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Selecciona una foto desde tu galería o archivos',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
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

              // BOTÓN GUARDAR PRODUCTO
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveProduct,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _isSaving
                          ? 'Guardando...'
                          : 'Guardar en ${_selectedCategory.name}',
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
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

class _StepLabel extends StatelessWidget {
  final String stepNumber;
  final String title;

  const _StepLabel({
    required this.stepNumber,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 1.2),
          ),
          child: Text(
            stepNumber,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceAdjustButton extends StatelessWidget {
  final String label;
  final bool isPositive;
  final VoidCallback onTap;

  const _PriceAdjustButton({
    required this.label,
    this.isPositive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.primary : AppColors.textSecondary;
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

