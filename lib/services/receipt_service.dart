import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:encrocante_app/models/pedido_model.dart';
import 'package:encrocante_app/utils/number_to_words.dart';

class ReceiptService {
  
  Future<void> printReceipt(Pedido pedido, {String? paymentMethod, double? montoRecibido, double? vuelto, double? descuento, int? puntosCanjeados}) async {
    final doc = pw.Document();
    
    // Receipt Format (Thermo 80mm approx)
    final PdfPageFormat roll80 = PdfPageFormat(
       80 * PdfPageFormat.mm, 
       double.infinity, 
       marginAll: 5 * PdfPageFormat.mm
    );

    final font = await PdfGoogleFonts.nunitoExtraLight();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    final date = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final time = DateFormat('HH:mm').format(DateTime.now());
    
    // Calculations
    final totalOriginal = pedido.total;
    final discountAmount = descuento ?? pedido.descuento ?? 0.0;
    final totalPagar = totalOriginal - discountAmount;
    
    // Load logo
    pw.MemoryImage? imageLogo;
    try {
      final ByteData data = await rootBundle.load('assets/icon/logo_crocante.png');
      imageLogo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      print('Error cargando el logo para el ticket: $e');
    }

    doc.addPage(
      pw.Page(
        pageFormat: roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              if (imageLogo != null) ...[
                 pw.Center(child: pw.Image(imageLogo, width: 40)),
                 pw.SizedBox(height: 5),
              ],
              pw.Center(child: pw.Text('Restaurante En Crocante', style: pw.TextStyle(font: fontBold, fontSize: 10))),
              pw.Center(child: pw.Text('Av. Maria Elena Moyano Mz. F', style: pw.TextStyle(font: font, fontSize: 8))),
              pw.Center(child: pw.Text('Villa el Salvador LIMA', style: pw.TextStyle(font: font, fontSize: 8))),
              pw.SizedBox(height: 5),
              pw.Center(child: pw.Text('NOTA DE VENTA / PEDIDO', style: pw.TextStyle(font: fontBold, fontSize: 9))),
              pw.SizedBox(height: 5),
              pw.Center(child: pw.Text('TICKET: ${_generateSerie(pedido.id)}', style: pw.TextStyle(font: fontBold, fontSize: 14))),
              pw.SizedBox(height: 5),
              
              // INFO
              pw.Text('ATENCIÓN: ${pedido.tipo.toUpperCase()}', style: pw.TextStyle(font: fontBold, fontSize: 8)),
              if (pedido.tipo.toLowerCase() == 'mesa')
                 pw.Text('MESA: ${pedido.mesaId ?? "?"}', style: pw.TextStyle(font: font, fontSize: 8)),
              
              pw.Text('MOZO: ${pedido.nombreMesero ?? "GENERAL"}', style: pw.TextStyle(font: font, fontSize: 8)), 
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('FECHA: $date', style: pw.TextStyle(font: font, fontSize: 8)),
                   pw.Text('HORA: $time', style: pw.TextStyle(font: font, fontSize: 8)),
                ]
              ),
              pw.Text('CLIENTE: ${pedido.nombreCliente ?? "VARIOS"}', style: pw.TextStyle(font: font, fontSize: 8)),
              if (paymentMethod != null)
                pw.Text('PAGO: ${paymentMethod.toUpperCase()}', style: pw.TextStyle(font: fontBold, fontSize: 8)),

              pw.Divider(thickness: 0.5),

              // ITEMS
              ...pedido.detalles.map((d) {
                 return pw.Container(
                   margin: const pw.EdgeInsets.only(bottom: 2),
                   child: pw.Row(
                     crossAxisAlignment: pw.CrossAxisAlignment.start,
                     children: [
                       pw.Expanded(
                         child: pw.Text('${d.cantidad} ${d.nombrePlatillo?.toUpperCase() ?? "ITEM"}', style: pw.TextStyle(font: font, fontSize: 8))
                       ),
                       pw.Text(d.subtotal.toStringAsFixed(2), style: pw.TextStyle(font: font, fontSize: 8)),
                     ]
                   )
                 );
              }),

              pw.Divider(thickness: 0.5),

              if (pedido.costoDelivery != null && pedido.costoDelivery! > 0) ...[
                 _buildRow('COSTO DELIVERY', pedido.costoDelivery!, font),
                 pw.SizedBox(height: 2),
              ],

              // TOTALS
              if (discountAmount > 0) ...[
                 pw.Row(
                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                   children: [
                     pw.Text('SUBTOTAL', style: pw.TextStyle(font: font, fontSize: 8)),
                     pw.Text('S/ ${totalOriginal.toStringAsFixed(2)}', style: pw.TextStyle(font: font, fontSize: 8)),
                   ]
                 ),
                 pw.Row(
                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                   children: [
                     pw.Text('DESCUENTO PUNTOS', style: pw.TextStyle(font: font, fontSize: 8)),
                     pw.Text('- S/ ${discountAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: font, fontSize: 8)),
                   ]
                 ),
                 pw.SizedBox(height: 2),
              ],
              
              pw.SizedBox(height: 2),

              pw.Row(
                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                 children: [
                   pw.Text('TOTAL A PAGAR', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                   pw.Text('S/ ${totalPagar.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                 ]
              ),
              
              pw.SizedBox(height: 5),

              // TOTAL IN WORDS
              pw.Text('SON: ${NumberToWords.convert(totalPagar)}', style: pw.TextStyle(font: font, fontSize: 8)),

              pw.SizedBox(height: 10),
              
              // PAYMENT DETAILS (If Cash)
              if (paymentMethod == 'Efectivo') ...[
                 pw.Row(
                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                   children: [
                     pw.Text('EFECTIVO', style: pw.TextStyle(font: font, fontSize: 8)),
                     pw.Text(montoRecibido != null ? montoRecibido.toStringAsFixed(2) : totalPagar.toStringAsFixed(2), style: pw.TextStyle(font: font, fontSize: 8)),
                   ]
                 ),
                  pw.Row(
                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                   children: [
                     pw.Text('VUELTO', style: pw.TextStyle(font: font, fontSize: 8)),
                     pw.Text(vuelto != null ? vuelto.toStringAsFixed(2) : '0.00', style: pw.TextStyle(font: font, fontSize: 8)), 
                   ]
                 ),
              ],
              
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('Gracias por su preferencia!', style: pw.TextStyle(font: font, fontSize: 8, fontStyle: pw.FontStyle.italic))),
            ]
          );
        }
      )
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Nota_Venta_${_generateSerie(pedido.id)}'
    );
  }

  pw.Widget _buildRow(String label, double amount, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 8)),
        pw.Text('S/ ${amount.toStringAsFixed(2)}', style: pw.TextStyle(font: font, fontSize: 8)),
      ]
    );
  }

  String _generateSerie(int id) {
    return 'P-${id.toString().padLeft(2, '0')}';
  }
}
