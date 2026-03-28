import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:encrocante_app/models/pedido_model.dart';
import 'package:encrocante_app/models/platillo_model.dart';

class TicketGenerator {
  
  static Future<void> printTicket(Pedido pedido) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    
    // Formato de fecha
    final String fecha = DateFormat('dd/MM/yyyy HH:mm').format(pedido.createdAt.toLocal());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Rollo de 80mm
        margin: const pw.EdgeInsets.all(5), // Márgenes mínimos
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabecera
              pw.Center(
                child: pw.Text('RESTAURANTE ENCROCANTE', style: pw.TextStyle(font: fontBold, fontSize: 16)),
              ),
              pw.Center(child: pw.Text('Ticket de Venta', style: pw.TextStyle(font: font, fontSize: 10))),
              pw.Divider(),
              
              // Datos del Pedido
              pw.Text('Pedido: #${pedido.id}', style: pw.TextStyle(font: fontBold, fontSize: 12)),
              pw.Text('Mesa: ${pedido.mesaId}', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text('Mozo: ${pedido.nombreMesero ?? "Sin asignar"}', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.createdAt.toLocal())}', style: pw.TextStyle(font: font, fontSize: 10)),
              if (pedido.metodoPago != null)
                pw.Text('Pago: ${pedido.metodoPago}', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Divider(),

              // Items
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Expanded(flex: 3, child: pw.Text('Cant x Desc', style: pw.TextStyle(font: fontBold, fontSize: 10))),
                   pw.Text('Total', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                ]
              ),
              pw.SizedBox(height: 5),
              ...pedido.matchDetalles(pedido.detalles).map((item) {
                final double subtotal = (item.precioUnitario ?? 0) * item.cantidad;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 3, 
                        child: pw.Text('${item.cantidad} x ${item.nombrePlatillo}', style: pw.TextStyle(font: font, fontSize: 9))
                      ),
                      pw.Text('S/ ${subtotal.toStringAsFixed(2)}', style: pw.TextStyle(font: font, fontSize: 9)),
                    ]
                  ));
              }),
              pw.Divider(),

              // Totales
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                  pw.Text('S/ ${pedido.total.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                ]
              ),
              
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('¡Gracias por su preferencia!', style: pw.TextStyle(font: font, fontSize: 8))),
              pw.Center(child: pw.Text('www.encrocante.com', style: pw.TextStyle(font: font, fontSize: 8))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Ticket-${pedido.id}',
    );
  }
}

// Extension auxiliar para mapear detalles si la estructura es compleja
extension PedidoHelper on Pedido {
  // Los detalles en PedidoModel pueden ser raw json o objetos.
  // Asumimos que PedidoModel tiene una lista de DetallePedido con nombre, cantidad, precio.
  // Si no, necesitaremos ajustar este mapeo.
  List<DetalleTicketStub> matchDetalles(List<dynamic> detallesRaw) {
      if (detallesRaw.isEmpty) return [];
      // Intentamos mapear estructura dinámica a stub
      return detallesRaw.map((d) {
         // Ajustar según estructura real de DetallePedido en el modelo
         // d puede ser Map o instancia de DetallePedido
         if (d is Map) {
            return DetalleTicketStub(
               nombrePlatillo: d['platillo_nombre'] ?? d['nombre'] ?? 'Item',
               cantidad: int.tryParse(d['cantidad'].toString()) ?? 1,
               precioUnitario: double.tryParse(d['precio_unitario']?.toString() ?? d['precio']?.toString() ?? '0') ?? 0.0
            );
         } else if (d is PedidoDetalle) {
             return DetalleTicketStub(
                nombrePlatillo: d.nombrePlatillo ?? 'Item #${d.platilloId}',
                cantidad: d.cantidad,
                precioUnitario: d.precioUnitario
             );
         } else {
             return DetalleTicketStub(nombrePlatillo: "Desconocido", cantidad: 0, precioUnitario: 0);
         }
      }).toList();
  }
}

class DetalleTicketStub {
  final String nombrePlatillo;
  final int cantidad;
  final double precioUnitario;
  DetalleTicketStub({required this.nombrePlatillo, required this.cantidad, required this.precioUnitario});
}
