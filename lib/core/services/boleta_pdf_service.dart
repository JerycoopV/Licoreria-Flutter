import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/boleta.dart';

/// Servicio para generar documentos PDF de boletas y compartirlos vía WhatsApp, correo u otras apps.
class BoletaPdfService {
  BoletaPdfService._();

  /// Genera los bytes del documento PDF de la boleta con formato de recibo / ticket comercial
  static Future<Uint8List> generateBoletaPdf(Boleta boleta) async {
    pw.Font? fontRegular;
    pw.Font? fontBold;
    try {
      fontRegular = await PdfGoogleFonts.robotoRegular();
      fontBold = await PdfGoogleFonts.robotoBold();
    } catch (_) {
      // En modo sin conexión usa la tipografía estándar del sistema
    }

    final pdf = pw.Document(
      theme: (fontRegular != null && fontBold != null)
          ? pw.ThemeData.withFont(base: fontRegular, bold: fontBold)
          : null,
    );

    // Formato estilo recibo de punto de venta (80mm de ancho)
    const roll80Format = PdfPageFormat(
      80 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 4 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: roll80Format,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Encabezado
                pw.Text(
                  'LICORERÍA POS',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'BOLETA DE VENTA ELECTRÓNICA',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    boleta.numero,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

                pw.SizedBox(height: 8),
                _buildDottedDivider(),
                pw.SizedBox(height: 6),

                // Metadatos
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Fecha:', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                    pw.Text(
                      boleta.fechaFormateada,
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Productos:', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                    pw.Text(
                      '${boleta.cantidadProductos} un. (${boleta.items.length} ítems)',
                      style: const pw.TextStyle(fontSize: 7.5),
                    ),
                  ],
                ),

                pw.SizedBox(height: 6),
                _buildDottedDivider(),
                pw.SizedBox(height: 6),

                // Cabecera de la lista de ítems
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text('DESCRIPCIÓN', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(
                      width: 38,
                      child: pw.Text('Cantidad', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(
                      width: 48,
                      child: pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 4),

                // Lista de productos
                ...boleta.items.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;
                  final catLabel = item.categoria.toLowerCase().contains('(${item.metodoPago.toLowerCase()})')
                      ? item.categoria
                      : '${item.categoria} (${item.metodoPago})';

                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(
                          width: 16,
                          child: pw.Text(
                            '$index)',
                            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                item.nombre,
                                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                              ),
                              pw.Text(
                                catLabel,
                                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(
                          width: 38,
                          child: pw.Text(
                            'x${item.cantidad}',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 7.5),
                          ),
                        ),
                        pw.SizedBox(
                          width: 48,
                          child: pw.Text(
                            'S/. ${item.subtotal.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            maxLines: 1,
                            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 6),
                _buildDottedDivider(),
                pw.SizedBox(height: 6),

                // Desglose de pagos
                if (boleta.totalEfectivo > 0)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Pago Efectivo:', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                        pw.Text(
                          'S/. ${boleta.totalEfectivo.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 7.5),
                        ),
                      ],
                    ),
                  ),

                if (boleta.totalYape > 0)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Pago Yape:', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                        pw.Text(
                          'S/. ${boleta.totalYape.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 7.5),
                        ),
                      ],
                    ),
                  ),

                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL A PAGAR',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'S/. ${boleta.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 10),
                pw.Text(
                  '¡Gracias por su compra!',
                  style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Documento comercial no fiscal emitido por Licorería POS',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey500),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Abre la hoja de compartir nativa (WhatsApp, Correo, Drive, etc.) con el archivo PDF adjunto
  static Future<void> shareBoletaPdf(Boleta boleta) async {
    final pdfBytes = await generateBoletaPdf(boleta);
    final filename = 'Boleta_${boleta.numero.replaceAll('-', '_')}.pdf';
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  }

  /// Abre la vista previa del sistema para imprimir o guardar como PDF en el dispositivo
  static Future<void> printOrSavePdf(Boleta boleta) async {
    final pdfBytes = await generateBoletaPdf(boleta);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Boleta_${boleta.numero}',
    );
  }

  static pw.Widget _buildDottedDivider() {
    return pw.Container(
      height: 1,
      child: pw.Row(
        children: List.generate(
          30,
          (_) => pw.Expanded(
            child: pw.Container(
              height: 0.8,
              color: PdfColors.grey400,
              margin: const pw.EdgeInsets.symmetric(horizontal: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
