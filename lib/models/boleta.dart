import 'package:intl/intl.dart';

/// Representa un producto individual dentro de una boleta emitida.
class BoletaItem {
  final String id;
  final String nombre;
  final String categoria;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String metodoPago;
  final double? montoEfectivo;
  final double? montoYape;

  const BoletaItem({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.metodoPago,
    this.montoEfectivo,
    this.montoYape,
  });

  bool get isSplitPayment =>
      montoEfectivo != null &&
      montoYape != null &&
      montoEfectivo! > 0 &&
      montoYape! > 0;

  double get efectivoAmount =>
      montoEfectivo ??
      (metodoPago.toLowerCase() == 'efectivo' ? subtotal : 0.0);

  double get yapeAmount =>
      montoYape ?? (metodoPago.toLowerCase() == 'yape' ? subtotal : 0.0);

  double get tarjetaAmount =>
      metodoPago.toLowerCase().contains('tarjeta') ? subtotal : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'metodo_pago': metodoPago,
      if (montoEfectivo != null) 'monto_efectivo': montoEfectivo,
      if (montoYape != null) 'monto_yape': montoYape,
    };
  }

  factory BoletaItem.fromMap(Map<String, dynamic> map) {
    final qty = ((map['cantidad'] ?? 1) as num).toInt();
    final pUnit = ((map['precio_unitario'] ?? 0.0) as num).toDouble();
    final sub = map['subtotal'] != null
        ? ((map['subtotal'] ?? 0.0) as num).toDouble()
        : (qty * pUnit);

    return BoletaItem(
      id: (map['id'] ?? '').toString(),
      nombre: (map['nombre'] ?? 'Producto').toString(),
      categoria: (map['categoria'] ?? 'General').toString(),
      cantidad: qty > 0 ? qty : 1,
      precioUnitario: pUnit,
      subtotal: sub,
      metodoPago: (map['metodo_pago'] ?? 'Efectivo').toString(),
      montoEfectivo: map['monto_efectivo'] != null
          ? (map['monto_efectivo'] as num).toDouble()
          : null,
      montoYape: map['monto_yape'] != null
          ? (map['monto_yape'] as num).toDouble()
          : null,
    );
  }
}

/// Representa un descuento aplicado a la boleta (ej. pago de personal, gastos, etc.)
/// indicando el motivo/nombre, cuánto se resta y si se descuenta de Efectivo o Yape.
class BoletaDescuento {
  final String id;
  final String nombre;
  final double monto;
  final String metodoPago; // 'Efectivo' o 'Yape'

  const BoletaDescuento({
    required this.id,
    required this.nombre,
    required this.monto,
    required this.metodoPago,
  });

  bool get isYape => metodoPago.toLowerCase() == 'yape';
  bool get isEfectivo => !isYape;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'monto': monto,
      'metodo_pago': metodoPago,
    };
  }

  factory BoletaDescuento.fromMap(Map<String, dynamic> map) {
    return BoletaDescuento(
      id: (map['id'] ?? '').toString(),
      nombre: (map['nombre'] ?? 'Descuento').toString(),
      monto: ((map['monto'] ?? 0.0) as num).toDouble(),
      metodoPago: (map['metodo_pago'] ?? 'Efectivo').toString(),
    );
  }
}

/// Modelo de Boleta de Venta emitida que agrupa los productos vendidos con fecha y hora actual.
class Boleta {
  final String id;
  final String numero;
  final DateTime fecha;
  final List<BoletaItem> items;
  final List<BoletaDescuento> descuentos;
  final double total;
  final double totalEfectivo;
  final double totalYape;
  final double totalTarjeta;
  final int cantidadProductos;
  final String? nota;

  Boleta({
    required this.id,
    required this.numero,
    DateTime? fecha,
    required this.items,
    this.descuentos = const [],
    double? total,
    double? totalEfectivo,
    double? totalYape,
    double? totalTarjeta,
    int? cantidadProductos,
    this.nota,
  })  : fecha = fecha ?? DateTime.now(),
        totalEfectivo = totalEfectivo ??
            items.fold(0.0, (sum, i) => sum + i.efectivoAmount),
        totalYape = totalYape ??
            items.fold(0.0, (sum, i) => sum + i.yapeAmount),
        totalTarjeta = totalTarjeta ??
            items.fold(0.0, (sum, i) => sum + i.tarjetaAmount),
        cantidadProductos = cantidadProductos ??
            items.fold(0, (sum, i) => sum + i.cantidad),
        total = total ??
            (items.fold(0.0, (sum, i) => sum + i.subtotal) -
                descuentos.fold(0.0, (sum, d) => sum + d.monto));

  double get subtotalProductos =>
      items.fold(0.0, (sum, i) => sum + i.subtotal);

  double get totalDescuentos =>
      descuentos.fold(0.0, (sum, d) => sum + d.monto);

  double get descuentoEfectivo => descuentos
      .where((d) => d.isEfectivo)
      .fold(0.0, (sum, d) => sum + d.monto);

  double get descuentoYape =>
      descuentos.where((d) => d.isYape).fold(0.0, (sum, d) => sum + d.monto);

  Boleta copyWith({
    String? id,
    String? numero,
    DateTime? fecha,
    List<BoletaItem>? items,
    List<BoletaDescuento>? descuentos,
    String? nota,
  }) {
    final nextItems = items ?? this.items;
    final nextDescuentos = descuentos ?? this.descuentos;
    return Boleta(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      fecha: fecha ?? this.fecha,
      items: nextItems,
      descuentos: nextDescuentos,
      nota: nota ?? this.nota,
    );
  }

  String get fechaFormateada {
    final formatter = DateFormat('dd/MM/yyyy, hh:mm a');
    return formatter.format(fecha);
  }

  String get fechaCorta {
    final formatter = DateFormat('dd MMM, hh:mm a');
    return formatter.format(fecha);
  }

  /// Genera una representación en texto plano tipo ticket térmico lista para imprimir o compartir
  String toPlainTextTicket() {
    final buffer = StringBuffer();
    buffer.writeln('================================');
    buffer.writeln('         LICORERÍA POS          ');
    buffer.writeln('       BOLETA DE VENTA          ');
    buffer.writeln('        N° $numero              ');
    buffer.writeln('--------------------------------');
    buffer.writeln('Fecha: $fechaFormateada');
    buffer.writeln('--------------------------------');
    buffer.writeln('DESCRIPCIÓN      CANTIDAD  TOTAL');
    buffer.writeln('--------------------------------');

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      buffer.writeln('${i + 1}) ${item.nombre}');
      final cantLabel = 'Cant: x${item.cantidad} (${item.metodoPago})';
      final sub = 'S/. ${item.subtotal.toStringAsFixed(2)}';
      final padding = 32 - cantLabel.length - sub.length;
      final spaces = padding > 0 ? ' ' * padding : '  ';
      buffer.writeln('  $cantLabel$spaces$sub');
    }

    buffer.writeln('--------------------------------');
    if (totalEfectivo > 0) {
      buffer.writeln('Efectivo:      S/. ${totalEfectivo.toStringAsFixed(2)}');
    }
    if (totalYape > 0) {
      buffer.writeln('Yape:          S/. ${totalYape.toStringAsFixed(2)}');
    }
    if (totalTarjeta > 0) {
      buffer.writeln('Tarjeta:       S/. ${totalTarjeta.toStringAsFixed(2)}');
    }
    for (final d in descuentos) {
      buffer.writeln(
        'Descuento (${d.nombre}) [${d.metodoPago}]: -S/. ${d.monto.toStringAsFixed(2)}',
      );
    }
    buffer.writeln('Total:         S/. ${total.toStringAsFixed(2)}');
    buffer.writeln('================================');
    buffer.writeln('    ¡Gracias por su compra!     ');
    buffer.writeln('================================');

    return buffer.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'fecha': fecha.toIso8601String(),
      'items': items.map((i) => i.toMap()).toList(),
      'descuentos': descuentos.map((d) => d.toMap()).toList(),
      'total': total,
      'total_efectivo': totalEfectivo,
      'total_yape': totalYape,
      'total_tarjeta': totalTarjeta,
      'cantidad_productos': cantidadProductos,
      if (nota != null) 'nota': nota,
    };
  }

  factory Boleta.fromMap(Map<String, dynamic> map) {
    List<BoletaItem> parsedItems = [];
    if (map['items'] is List) {
      parsedItems = (map['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map((i) => BoletaItem.fromMap(i))
          .toList();
    }

    List<BoletaDescuento> parsedDescuentos = [];
    if (map['descuentos'] is List) {
      parsedDescuentos = (map['descuentos'] as List)
          .whereType<Map<String, dynamic>>()
          .map((d) => BoletaDescuento.fromMap(d))
          .toList();
    }

    return Boleta(
      id: (map['id'] ?? '').toString(),
      numero: (map['numero'] ?? 'B001-00001').toString(),
      fecha: map['fecha'] != null
          ? DateTime.tryParse(map['fecha'] as String) ?? DateTime.now()
          : DateTime.now(),
      items: parsedItems,
      descuentos: parsedDescuentos,
      total: map['total'] != null
          ? ((map['total'] ?? 0.0) as num).toDouble()
          : null,
      totalEfectivo: ((map['total_efectivo'] ?? 0.0) as num).toDouble(),
      totalYape: ((map['total_yape'] ?? 0.0) as num).toDouble(),
      totalTarjeta: map['total_tarjeta'] != null
          ? ((map['total_tarjeta'] ?? 0.0) as num).toDouble()
          : null,
      cantidadProductos: ((map['cantidad_productos'] ?? 0) as num).toInt(),
      nota: map['nota'] as String?,
    );
  }
}
