import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sale.dart';

/// Repositorio y gestor reactivo para el historial de ventas.
/// Almacena 100% offline todas las operaciones de venta localmente usando SharedPreferences/JSON.
class SalesRepository extends ChangeNotifier {
  static const String _storageKey = 'licoreria_sales_history_v1';

  // Patrón Singleton para acceso global y desacoplado
  static final SalesRepository _instance = SalesRepository._internal();
  factory SalesRepository() => _instance;

  SalesRepository._internal() {
    loadSales();
  }

  final List<Sale> _sales = [];
  bool _isLoaded = false;

  List<Sale> get sales => List.unmodifiable(_sales);
  bool get isLoaded => _isLoaded;

  /// Carga las ventas almacenadas localmente en el dispositivo.
  /// En navegador (Web) o cuando se inicia desde 0 sin datos en caché, el historial inicia vacío.
  /// En móvil se conservan los datos guardados en caché (SharedPreferences) a menos que se borre el caché.
  Future<List<Sale>> loadSales() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (kIsWeb) {
        // En navegador siempre empieza desde 0 con el historial vacío al iniciar la aplicación
        _sales.clear();
        await prefs.remove(_storageKey);
        _isLoaded = true;
        notifyListeners();
        return _sales;
      }

      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
        _sales.clear();
        bool hadDemoData = false;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final sale = Sale.fromMap(item);
            // Ignorar ventas demostrativas antiguas si quedaron en caché
            if (sale.note == 'Venta inicial demostrativa') {
              hadDemoData = true;
              continue;
            }
            _sales.add(sale);
          }
        }
        if (hadDemoData) {
          await _persistSales();
        }
      } else {
        // Primera ejecución o caché borrado: el historial inicia completamente vacío
        _sales.clear();
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error cargando ventas locales: $e');
      _isLoaded = true;
    }

    notifyListeners();
    return _sales;
  }

  /// Persiste la lista completa de ventas localmente en el almacenamiento del dispositivo
  Future<bool> _persistSales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(_sales.map((s) => s.toMap()).toList());
      return await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error al persistir ventas offline: $e');
      return false;
    }
  }

  /// Total recaudado acumulado (cantidad × precio unitario)
  double get totalSalesAmount =>
      _sales.fold(0.0, (sum, item) => sum + item.total);

  /// Total recibido en Efectivo
  double get totalCashAmount =>
      _sales.fold(0.0, (sum, item) => sum + item.cashAmount);

  /// Total recibido por Yape
  double get totalYapeAmount =>
      _sales.fold(0.0, (sum, item) => sum + item.yapeAmount);

  /// Registra una nueva venta con validaciones estrictas
  Future<bool> recordSale(Sale sale) async {
    // Validaciones de negocio
    if (sale.cantidad <= 0) {
      debugPrint('Error: Cantidad debe ser mayor a 0');
      return false;
    }
    if (sale.precio < 0) {
      debugPrint('Error: Precio no puede ser negativo');
      return false;
    }
    if (sale.metodoPago.trim().isEmpty) {
      debugPrint('Error: Método de pago no puede estar vacío');
      return false;
    }

    _sales.insert(0, sale); // La venta más reciente al inicio
    notifyListeners();

    final saved = await _persistSales();
    return saved;
  }

  /// Elimina una venta del historial y actualiza el almacenamiento local
  Future<bool> removeSale(dynamic id) async {
    final idStr = id.toString();
    _sales.removeWhere((s) => s.id.toString() == idStr);
    notifyListeners();
    return await _persistSales();
  }

  /// Limpia todos los registros tanto en memoria como en almacenamiento local
  Future<bool> clearAll() async {
    _sales.clear();
    notifyListeners();
    return await _persistSales();
  }

  /// Obtiene todas las ventas pagadas con Yape
  List<Sale> getYapeSales() {
    return _sales.where((s) => s.metodoPago.toLowerCase() == 'yape').toList();
  }

  /// Combina una venta base de Yape con una o más ventas adicionales de Yape
  Future<bool> combineYapeSales({
    required Sale baseSale,
    required List<Sale> salesToCombine,
  }) async {
    if (salesToCombine.isEmpty) return false;

    // Verificar que todas sean ventas de Yape
    if (baseSale.metodoPago.toLowerCase() != 'yape' ||
        salesToCombine.any((s) => s.metodoPago.toLowerCase() != 'yape')) {
      debugPrint('Error: Solo se pueden combinar ventas pagadas con Yape');
      return false;
    }

    final allSales = [baseSale, ...salesToCombine];
    final totalAmount = allSales.fold(0.0, (sum, s) => sum + s.total);

    // Recolectar o construir ítems detallados de cada venta
    final allItems = <SaleItem>[];
    for (final s in allSales) {
      if (s.items.isNotEmpty) {
        allItems.addAll(s.items);
      } else {
        allItems.add(
          SaleItem(
            id: 'item_${s.id}',
            productId: s.id.toString(),
            productName: s.nombre,
            unitPrice: s.precio,
            quantity: s.cantidad,
          ),
        );
      }
    }

    // Construir nombre representativo de la combinación
    String combinedName;
    if (allSales.length == 2) {
      combinedName = '${allSales[0].nombre} + ${allSales[1].nombre}';
    } else {
      combinedName = '${allSales[0].nombre} + ${allSales.length - 1} productos más';
    }

    // Categoría: si todas tienen la misma categoría usarla, sino 'Varios (Yape)'
    final categories = allSales.map((s) => s.categoria).toSet();
    final combinedCategory = categories.length == 1
        ? categories.first
        : 'Varios (Yape)';

    // Fecha más reciente entre las ventas a combinar
    final latestDate = allSales
        .map((s) => s.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final combinedSale = Sale(
      id: 'yape_comb_${DateTime.now().millisecondsSinceEpoch}',
      nombre: combinedName,
      categoria: combinedCategory,
      cantidad: 1,
      precio: totalAmount,
      metodoPago: 'Yape',
      createdAt: latestDate,
      items: allItems,
      isCombined: true,
      originalSalesData: allSales.map((s) => s.toMap()).toList(),
      note: 'Venta combinada Yape (${allSales.length} productos)',
    );

    // Encontrar índice de la venta base para reemplazarla en la misma posición relativa
    final baseIndex =
        _sales.indexWhere((s) => s.id.toString() == baseSale.id.toString());

    // Eliminar las ventas originales que ahora forman parte del grupo
    final idsToRemove = allSales.map((s) => s.id.toString()).toSet();
    _sales.removeWhere((s) => idsToRemove.contains(s.id.toString()));

    // Insertar la venta combinada en la posición de la venta base
    final insertIndex =
        (baseIndex >= 0 && baseIndex <= _sales.length) ? baseIndex : 0;
    _sales.insert(insertIndex, combinedSale);

    notifyListeners();
    return await _persistSales();
  }

  /// Deshace una combinación restaurando las ventas originales
  Future<bool> separateCombinedSale(Sale combinedSale) async {
    if (!combinedSale.isCombined ||
        combinedSale.originalSalesData == null ||
        combinedSale.originalSalesData!.isEmpty) {
      return false;
    }

    final index = _sales
        .indexWhere((s) => s.id.toString() == combinedSale.id.toString());
    if (index < 0) return false;

    final originals = combinedSale.originalSales;
    _sales.removeAt(index);
    _sales.insertAll(index, originals);

    notifyListeners();
    return await _persistSales();
  }

  /// Divide el pago de una venta entre Efectivo y Yape
  Future<bool> splitSaleWithYape({
    required dynamic saleId,
    required double cashAmount,
    required double yapeAmount,
  }) async {
    final index =
        _sales.indexWhere((s) => s.id.toString() == saleId.toString());
    if (index < 0) return false;

    final current = _sales[index];
    if (cashAmount < 0 || yapeAmount < 0) return false;

    // Si todo vuelve a Efectivo (yape == 0)
    if (yapeAmount <= 0.001) {
      return await restoreSplitSaleToCash(saleId);
    }

    final updatedSale = Sale(
      id: current.id,
      nombre: current.nombre,
      categoria: current.categoria,
      cantidad: current.cantidad,
      precio: current.precio,
      metodoPago: 'Efectivo',
      cashAmount: cashAmount,
      yapeAmount: yapeAmount,
      createdAt: current.createdAt,
      note: current.note,
      items: current.items,
      isCombined: current.isCombined,
      originalSalesData: current.originalSalesData,
    );

    _sales[index] = updatedSale;
    notifyListeners();
    return await _persistSales();
  }

  /// Restaura una venta con pago dividido a 100% Efectivo
  Future<bool> restoreSplitSaleToCash(dynamic saleId) async {
    final index =
        _sales.indexWhere((s) => s.id.toString() == saleId.toString());
    if (index < 0) return false;

    final current = _sales[index];
    final restoredSale = Sale(
      id: current.id,
      nombre: current.nombre,
      categoria: current.categoria,
      cantidad: current.cantidad,
      precio: current.precio,
      metodoPago: 'Efectivo',
      createdAt: current.createdAt,
      note: current.note,
      items: current.items,
      isCombined: current.isCombined,
      originalSalesData: current.originalSalesData,
    );

    _sales[index] = restoredSale;
    notifyListeners();
    return await _persistSales();
  }
}
