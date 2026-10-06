
enum PaymentMethod {
  efectivo,
  yape,
  mixto;

  String get displayName {
    switch (this) {
      case PaymentMethod.efectivo:
        return 'Efectivo';
      case PaymentMethod.yape:
        return 'Yape';
      case PaymentMethod.mixto:
        return 'Mixto';
    }
  }
}

/// Detalle individual de un producto vendido.
class SaleItem {
  final String id;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  const SaleItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: (map['id'] ?? '').toString(),
      productId: (map['product_id'] ?? '').toString(),
      productName: (map['product_name'] ?? '').toString(),
      unitPrice: ((map['unit_price'] ?? 0) as num).toDouble(),
      quantity: ((map['quantity'] ?? 1) as num).toInt(),
    );
  }
}

/// Modelo de Venta para el historial de operaciones de la licorería.
/// Contiene: id, nombre, categoria, cantidad, precio (unitario) y metodoPago.
class Sale {
  final dynamic id;
  final String nombre;
  final String categoria;
  final int cantidad;
  final double precio; // PRECIO UNITARIO
  final String metodoPago;
  final DateTime createdAt;
  final String? note;
  final List<SaleItem> items;

  Sale({
    required this.id,
    String? nombre,
    String? categoria,
    int? cantidad,
    double? precio,
    String? metodoPago,
    PaymentMethod? paymentMethod,
    double? totalAmount,
    double? cashAmount,
    double? yapeAmount,
    DateTime? createdAt,
    this.note,
    this.items = const [],
  })  : nombre = nombre ?? (note ?? 'Venta'),
        categoria = categoria ?? 'General',
        cantidad = cantidad ?? 1,
        precio = precio ??
            ((totalAmount ?? 0.0) /
                ((cantidad != null && cantidad > 0) ? cantidad : 1)),
        metodoPago = metodoPago ?? (paymentMethod?.displayName ?? 'Efectivo'),
        createdAt = createdAt ?? DateTime.now();

  /// Total calculado automáticamente: cantidad × precio unitario
  double get total => precio * cantidad;

  // Getters para compatibilidad con widgets y métricas existentes
  double get totalAmount => total;
  double get cashAmount =>
      metodoPago.toLowerCase() == 'efectivo' ? total : 0.0;
  double get yapeAmount => metodoPago.toLowerCase() == 'yape' ? total : 0.0;
  PaymentMethod get paymentMethod => metodoPago.toLowerCase() == 'yape'
      ? PaymentMethod.yape
      : PaymentMethod.efectivo;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'cantidad': cantidad,
      'precio': precio,
      'metodo_pago': metodoPago,
      'created_at': createdAt.toIso8601String(),
      if (note != null) 'note': note,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map,
      [List<SaleItem> items = const []]) {
    final methodStr =
        (map['metodo_pago'] ?? map['payment_method'] ?? 'Efectivo').toString();
    final qty = ((map['cantidad'] ?? map['quantity'] ?? 1) as num).toInt();

    final unitPrice = map['precio'] != null
        ? (map['precio'] as num).toDouble()
        : (map['total_amount'] != null
            ? (map['total_amount'] as num).toDouble() / (qty > 0 ? qty : 1)
            : 0.0);

    return Sale(
      id: map['id'],
      nombre: (map['nombre'] ?? map['product_name'] ?? map['note'] ?? 'Venta')
          .toString(),
      categoria:
          (map['categoria'] ?? map['category'] ?? 'General').toString(),
      cantidad: qty > 0 ? qty : 1,
      precio: unitPrice,
      metodoPago: methodStr,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      note: map['note'] as String?,
      items: items,
    );
  }
}
