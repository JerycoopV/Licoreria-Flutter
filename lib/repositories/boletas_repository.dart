import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/boleta.dart';
import '../models/sale.dart';

/// Repositorio para gestionar, persistir y consultar el listado de boletas exportadas.
class BoletasRepository extends ChangeNotifier {
  static const String _storageKey = 'licoreria_boletas_history_v1';

  // Singleton
  static final BoletasRepository _instance = BoletasRepository._internal();
  factory BoletasRepository() => _instance;

  BoletasRepository._internal() {
    loadBoletas();
  }

  final List<Boleta> _boletas = [];
  bool _isLoaded = false;

  List<Boleta> get boletas => List.unmodifiable(_boletas);
  bool get isLoaded => _isLoaded;
  int get count => _boletas.length;

  double get totalBoletasAmount =>
      _boletas.fold(0.0, (sum, b) => sum + b.total);

  /// Carga todas las boletas guardadas localmente
  Future<List<Boleta>> loadBoletas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
        _boletas.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _boletas.add(Boleta.fromMap(item));
          }
        }
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error al cargar boletas locales: $e');
      _isLoaded = true;
    }

    notifyListeners();
    return _boletas;
  }

  /// Guarda el listado en almacenamiento local
  Future<bool> _persistBoletas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(_boletas.map((b) => b.toMap()).toList());
      return await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error al persistir boletas: $e');
      return false;
    }
  }

  /// Construye una boleta en memoria a partir de las ventas actuales (sin guardarla aún)
  Boleta buildBoletaFromSales(
    List<Sale> sales, {
    String? nota,
    DateTime? customDate,
  }) {
    if (sales.isEmpty) {
      throw ArgumentError('No se pueden exportar ventas vacías');
    }

    final boletaItems = <BoletaItem>[];

    for (final sale in sales) {
      if (sale.isCombined && sale.items.isNotEmpty) {
        // Desglosar ítems individuales de la venta combinada
        for (final item in sale.items) {
          boletaItems.add(
            BoletaItem(
              id: item.id.isNotEmpty
                  ? item.id
                  : 'item_${DateTime.now().microsecondsSinceEpoch}',
              nombre: item.productName,
              categoria: sale.categoria,
              cantidad: item.quantity,
              precioUnitario: item.unitPrice,
              subtotal: item.subtotal,
              metodoPago: sale.metodoPago,
            ),
          );
        }
      } else {
        boletaItems.add(
          BoletaItem(
            id: sale.id.toString(),
            nombre: sale.nombre,
            categoria: sale.categoria,
            cantidad: sale.cantidad,
            precioUnitario: sale.precio,
            subtotal: sale.total,
            metodoPago: sale.isSplitPayment
                ? 'Efectivo (S/. ${sale.cashAmount.toStringAsFixed(2)}) + Yape (S/. ${sale.yapeAmount.toStringAsFixed(2)})'
                : sale.metodoPago,
            montoEfectivo: sale.isSplitPayment ? sale.cashAmount : null,
            montoYape: sale.isSplitPayment ? sale.yapeAmount : null,
          ),
        );
      }
    }

    final now = customDate ?? DateTime.now();
    final nextNumber = _boletas.length + 1;
    final numeroFormateado = 'B001-${nextNumber.toString().padLeft(5, '0')}';

    return Boleta(
      id: 'boleta_${now.millisecondsSinceEpoch}',
      numero: numeroFormateado,
      fecha: now,
      items: boletaItems,
      nota: nota,
    );
  }

  /// Guarda una boleta en el listado de boletas y la persiste localmente
  Future<bool> saveBoleta(Boleta boleta) async {
    final alreadyExists = _boletas.any((b) => b.id == boleta.id);
    if (!alreadyExists) {
      _boletas.insert(0, boleta);
      notifyListeners();
    }
    return await _persistBoletas();
  }

  /// Crea y guarda una nueva boleta a partir de los productos registrados en ventas
  Future<Boleta> createBoletaFromSales(
    List<Sale> sales, {
    String? nota,
    DateTime? customDate,
  }) async {
    final boleta = buildBoletaFromSales(
      sales,
      nota: nota,
      customDate: customDate,
    );
    await saveBoleta(boleta);
    return boleta;
  }

  /// Elimina una boleta por su identificador
  Future<bool> deleteBoleta(String id) async {
    _boletas.removeWhere((b) => b.id == id);
    notifyListeners();
    return await _persistBoletas();
  }

  /// Borra todo el historial de boletas
  Future<bool> clearAll() async {
    _boletas.clear();
    notifyListeners();
    return await _persistBoletas();
  }
}
