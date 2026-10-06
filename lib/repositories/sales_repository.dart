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

  /// Carga las ventas almacenadas localmente en el dispositivo
  Future<List<Sale>> loadSales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
        _sales.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _sales.add(Sale.fromMap(item));
          }
        }
      } else if (_sales.isEmpty) {
        // Primera ejecución: cargar datos demostrativos
        _loadInitialData();
        await _persistSales();
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error cargando ventas locales: $e');
      if (_sales.isEmpty) {
        _loadInitialData();
      }
      _isLoaded = true;
    }

    notifyListeners();
    return _sales;
  }

  /// Carga registros de demostración iniciales para la primera apertura
  void _loadInitialData() {
    final now = DateTime.now();
    _sales.addAll([
      Sale(
        id: 1,
        nombre: 'Pisco Portón Mosto Verde 750ml',
        categoria: 'Pisco',
        cantidad: 1,
        precio: 89.00,
        metodoPago: 'Yape',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 15)),
        note: 'Venta inicial demostrativa',
      ),
      Sale(
        id: 2,
        nombre: 'Six Pack Pilsen Callao Latas',
        categoria: 'Cervezas',
        cantidad: 2,
        precio: 32.00,
        metodoPago: 'Efectivo',
        createdAt: now.subtract(const Duration(hours: 5, minutes: 30)),
        note: 'Venta inicial demostrativa',
      ),
    ]);
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
}
