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
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      unitPrice: (map['unit_price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toInt(),
    );
  }
}

/// Registro completo de una venta efectuada en la licorería.
class Sale {
  final String id;
  final DateTime createdAt;
  final List<SaleItem> items;
  final double totalAmount;
  final double cashAmount;
  final double yapeAmount;
  final PaymentMethod paymentMethod;
  final String? note;

  const Sale({
    required this.id,
    required this.createdAt,
    this.items = const [],
    required this.totalAmount,
    this.cashAmount = 0.0,
    this.yapeAmount = 0.0,
    required this.paymentMethod,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'total_amount': totalAmount,
      'cash_amount': cashAmount,
      'yape_amount': yapeAmount,
      'payment_method': paymentMethod.name,
      'note': note,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map, [List<SaleItem> items = const []]) {
    return Sale(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: items,
      totalAmount: (map['total_amount'] as num).toDouble(),
      cashAmount: (map['cash_amount'] as num?)?.toDouble() ?? 0.0,
      yapeAmount: (map['yape_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.values.byName(map['payment_method'] as String),
      note: map['note'] as String?,
    );
  }
}
