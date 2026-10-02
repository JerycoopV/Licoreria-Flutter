import 'package:flutter/foundation.dart';
import '../models/sale.dart';

/// Repositorio y gestor reactivo para el historial de ventas.
/// En fases posteriores se conectará con la base de datos local (SQLite/Sembast).
class SalesRepository extends ChangeNotifier {
  // Patrón Singleton para acceso global y desacoplado
  static final SalesRepository _instance = SalesRepository._internal();
  factory SalesRepository() => _instance;

  SalesRepository._internal() {
    _loadInitialData();
  }

  final List<Sale> _sales = [];

  List<Sale> get sales => List.unmodifiable(_sales);

  /// Carga registros de demostración iniciales para comprobar la interfaz visual del historial.
  void _loadInitialData() {
    final now = DateTime.now();
    _sales.addAll([
      Sale(
        id: 'sale_001',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 15)),
        totalAmount: 48.50,
        cashAmount: 0.0,
        yapeAmount: 48.50,
        paymentMethod: PaymentMethod.yape,
        note: 'Venta demostrativa (Yape)',
      ),
      Sale(
        id: 'sale_002',
        createdAt: now.subtract(const Duration(hours: 5, minutes: 30)),
        totalAmount: 75.00,
        cashAmount: 75.00,
        yapeAmount: 0.0,
        paymentMethod: PaymentMethod.efectivo,
        note: 'Venta demostrativa (Efectivo)',
      ),
    ]);
  }

  /// Total recaudado acumulado
  double get totalSalesAmount =>
      _sales.fold(0.0, (sum, item) => sum + item.totalAmount);

  /// Total recibido en Efectivo
  double get totalCashAmount =>
      _sales.fold(0.0, (sum, item) => sum + item.cashAmount);

  /// Total recibido por Yape
  double get totalYapeAmount =>
      _sales.fold(0.0, (sum, item) => sum + item.yapeAmount);

  /// Registra una nueva venta
  void recordSale(Sale sale) {
    _sales.insert(0, sale); // La venta más reciente al inicio
    notifyListeners();
  }

  /// Elimina una venta
  void removeSale(String id) {
    _sales.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  /// Limpia todos los registros (útil para pruebas)
  void clearAll() {
    _sales.clear();
    notifyListeners();
  }
}
