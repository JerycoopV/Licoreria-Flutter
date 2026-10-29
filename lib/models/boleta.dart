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

  const BoletaItem({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.metodoPago,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'metodo_pago': metodoPago,
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
    );
  }
}

/// Modelo de Boleta de Venta emitida que agrupa los productos vendidos con fecha y hora actual.
class Boleta {
  final String id;
  final String numero;
  final DateTime fecha;
  final List<BoletaItem> items;
  final double total;
  final double totalEfectivo;
  final double totalYape;
  final int cantidadProductos;
  final String? nota;

  Boleta({
    required this.id,
    required this.numero,
    DateTime? fecha,
    required this.items,
    double? total,
    double? totalEfectivo,
    double? totalYape,
    int? cantidadProductos,
    this.nota,
  })  : fecha = fecha ?? DateTime.now(),
        total = total ?? items.fold(0.0, (sum, i) => sum + i.subtotal),
        totalEfectivo = totalEfectivo ??
            items
                .where((i) => i.metodoPago.toLowerCase() == 'efectivo')
                .fold(0.0, (sum, i) => sum + i.subtotal),
        totalYape = totalYape ??
            items
                .where((i) => i.metodoPago.toLowerCase() == 'yape')
                .fold(0.0, (sum, i) => sum + i.subtotal),
        cantidadProductos = cantidadProductos ??
            items.fold(0, (sum, i) => sum + i.cantidad);

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
    buffer.writeln('CANT  PRODUCTO           TOTAL  ');
    buffer.writeln('--------------------------------');

    for (final item in items) {
      buffer.writeln('${item.cantidad}x ${item.nombre}');
      final pUnit = 'P.U: S/. ${item.precioUnitario.toStringAsFixed(2)} (${item.metodoPago})';
      final sub = 'S/. ${item.subtotal.toStringAsFixed(2)}';
      final padding = 32 - pUnit.length - sub.length;
      final spaces = padding > 0 ? ' ' * padding : '  ';
      buffer.writeln('  $pUnit$spaces$sub');
    }

    buffer.writeln('--------------------------------');
    if (totalEfectivo > 0) {
      buffer.writeln('Efectivo:      S/. ${totalEfectivo.toStringAsFixed(2)}');
    }
    if (totalYape > 0) {
      buffer.writeln('Yape:          S/. ${totalYape.toStringAsFixed(2)}');
    }
    buffer.writeln('TOTAL A PAGAR: S/. ${total.toStringAsFixed(2)}');
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
      'total': total,
      'total_efectivo': totalEfectivo,
      'total_yape': totalYape,
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

    return Boleta(
      id: (map['id'] ?? '').toString(),
      numero: (map['numero'] ?? 'B001-00001').toString(),
      fecha: map['fecha'] != null
          ? DateTime.tryParse(map['fecha'] as String) ?? DateTime.now()
          : DateTime.now(),
      items: parsedItems,
      total: ((map['total'] ?? 0.0) as num).toDouble(),
      totalEfectivo: ((map['total_efectivo'] ?? 0.0) as num).toDouble(),
      totalYape: ((map['total_yape'] ?? 0.0) as num).toDouble(),
      cantidadProductos: ((map['cantidad_productos'] ?? 0) as num).toInt(),
      nota: map['nota'] as String?,
    );
  }
}
