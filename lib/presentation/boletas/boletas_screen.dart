import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../models/boleta.dart';
import '../../repositories/boletas_repository.dart';
import '../home/widgets/boleta_receipt_modal.dart';

/// Pantalla que muestra el Listado de Boletas emitidas y guardadas localmente.
class BoletasScreen extends StatefulWidget {
  const BoletasScreen({super.key});

  @override
  State<BoletasScreen> createState() => _BoletasScreenState();
}

class _BoletasScreenState extends State<BoletasScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boletasRepo = BoletasRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Boletas'),
        actions: [
          ListenableBuilder(
            listenable: boletasRepo,
            builder: (context, _) {
              if (boletasRepo.boletas.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Limpiar todas las boletas',
                onPressed: () => _confirmClearAll(context, boletasRepo),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          child: ListenableBuilder(
            listenable: boletasRepo,
            builder: (context, _) {
              final allBoletas = boletasRepo.boletas;
              final filteredBoletas = _filterBoletas(allBoletas);

              return Column(
                children: [
                  // Buscador y Resumen
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim().toLowerCase();
                            });
                          },
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Buscar por N° boleta o producto...',
                            hintStyle:
                                const TextStyle(color: AppColors.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: AppColors.textMuted),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded,
                                        color: AppColors.textMuted),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                        if (allBoletas.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${allBoletas.length} ${allBoletas.length == 1 ? 'boleta guardada' : 'boletas guardadas'}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Total: S/. ${boletasRepo.totalBoletasAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Lista de Boletas o Estado Vacío
                  Expanded(
                    child: allBoletas.isEmpty
                        ? _buildEmptyState()
                        : filteredBoletas.isEmpty
                            ? _buildNoResultsState()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                itemCount: filteredBoletas.length,
                                itemBuilder: (context, index) {
                                  final boleta = filteredBoletas[index];
                                  return _buildBoletaCard(
                                      context, boleta, boletasRepo);
                                },
                              ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Boleta> _filterBoletas(List<Boleta> boletas) {
    if (_searchQuery.isEmpty) return boletas;

    return boletas.where((b) {
      if (b.numero.toLowerCase().contains(_searchQuery)) return true;
      if (b.fechaFormateada.toLowerCase().contains(_searchQuery)) return true;
      return b.items.any(
          (item) => item.nombre.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No hay boletas guardadas',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando registres ventas en la pantalla principal, presiona el botón "Exporta Boleta" para guardarlas en este listado con la fecha actual.',
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
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'No se encontraron boletas para "$_searchQuery"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoletaCard(
    BuildContext context,
    Boleta boleta,
    BoletasRepository repo,
  ) {
    final hasEfectivo = boleta.totalEfectivo > 0;
    final hasYape = boleta.totalYape > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            BoletaReceiptModal.show(context, boleta: boleta);
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withValues(alpha: 0.1),
          highlightColor: AppColors.primary.withValues(alpha: 0.05),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera de la tarjeta: Número y Fecha actual
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          boleta.numero,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      boleta.fechaCorta,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Lista resumida de productos vendidos
                Text(
                  boleta.items.map((i) => '${i.cantidad}x ${i.nombre}').join(' • '),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: 10),

                // Fila inferior: Métodos de pago y Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (hasEfectivo)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.efectivo.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.payments_rounded,
                                    size: 12, color: AppColors.efectivo),
                                SizedBox(width: 4),
                                Text(
                                  'Efectivo',
                                  style: TextStyle(
                                    color: AppColors.efectivo,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (hasYape)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.yape.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.qr_code_rounded,
                                    size: 12, color: AppColors.yape),
                                SizedBox(width: 4),
                                Text(
                                  'Yape',
                                  style: TextStyle(
                                    color: AppColors.yape,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
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
                            Text(
                              'S/. ${boleta.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded,
                              size: 18, color: AppColors.textMuted),
                          color: AppColors.surfaceElevated,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.cardBorder),
                          ),
                          onSelected: (val) {
                            if (val == 'view') {
                              BoletaReceiptModal.show(context, boleta: boleta);
                            } else if (val == 'copy') {
                              Clipboard.setData(
                                  ClipboardData(text: boleta.toPlainTextTicket()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Boleta copiada al portapapeles'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else if (val == 'delete') {
                              _confirmDeleteBoleta(context, boleta, repo);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_outlined,
                                      size: 18, color: AppColors.primary),
                                  SizedBox(width: 10),
                                  Text('Ver Boleta'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'copy',
                              child: Row(
                                children: [
                                  Icon(Icons.copy_rounded,
                                      size: 18, color: AppColors.textSecondary),
                                  SizedBox(width: 10),
                                  Text('Copiar Texto'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded,
                                      size: 18, color: AppColors.error),
                                  SizedBox(width: 10),
                                  Text('Eliminar',
                                      style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  void _confirmDeleteBoleta(
    BuildContext context,
    Boleta boleta,
    BoletasRepository repo,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('¿Eliminar ${boleta.numero}?'),
        content: const Text(
          'Esta acción no se puede deshacer.',
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
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            onPressed: () {
              repo.deleteBoleta(boleta.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, BoletasRepository repo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Limpiar todas las boletas?'),
        content: const Text(
          'Se eliminarán todas las boletas guardadas del listado.',
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
            child: const Text('Limpiar todo',
                style: TextStyle(color: Colors.white)),
            onPressed: () {
              repo.clearAll();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}
