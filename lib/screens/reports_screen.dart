import 'package:flutter/material.dart';
import 'package:encrocante_app/services/report_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService();
  bool _isLoading = false;
  
  List<dynamic> _ventas = [];
  List<dynamic> _platillos = [];
  List<dynamic> _mozos = [];
  
  String? _errorMessage;
  
  // Filtros de Fecha
  DateTime? _startDate;
  DateTime? _endDate;
  String _filterLabel = "Esta Semana"; // Default to a valid dropdown option
  String _paymentMethod = "Todos"; // Filtro de metodo de pago

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Initialize default date range for "Esta Semana"
    _setFilterRange(7); 
    // _loadData is called inside _setFilterRange
  }

  // Flag to use server-side 'today' preset
  bool _usePresetToday = false;

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Pass preset if 'Today' is selected
      final ventas = await _reportService.getVentasDiarias(
        start: _startDate, 
        end: _endDate, 
        metodoPago: _paymentMethod,
        preset: _usePresetToday ? 'today' : null
      );
      final platillos = await _reportService.getTopPlatillos(start: _startDate, end: _endDate, metodoPago: _paymentMethod);
      final mozos = await _reportService.getRendimientoMozos(start: _startDate, end: _endDate); 

      if (mounted) {
        setState(() {
          _ventas = ventas;
          _platillos = platillos;
          _mozos = mozos;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- ADVANCED PDF EXPORT LOGIC ---
  Future<void> _exportPdf() async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    // Calculos Generales para el PDF
    final totalVentas = _ventas.fold<double>(0, (sum, v) => sum + (double.tryParse(v['total_ventas'].toString()) ?? 0));
    final totalPedidos = _ventas.fold<int>(0, (sum, v) => sum + ((v['cantidad_pedidos'] as int?) ?? 0));
    final ticketPromedio = totalPedidos > 0 ? totalVentas / totalPedidos : 0.0;

    // Logo (Simulado con texto por ahora)
    final profileImage = pw.Container(
      width: 40, height: 40,
      decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: PdfColors.orange),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('EN CROCANTE', style: pw.TextStyle(font: fontBold, fontSize: 28, color: PdfColors.orange800)),
                    pw.Text('Reporte Operativo y Estadístico', style: pw.TextStyle(font: font, fontSize: 14)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                     pw.Text('Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 10)),
                     pw.Text(
                       'Fechas: ${_filterLabel == "Personalizado" ? "${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}" : _filterLabel}', 
                       style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.blueGrey)
                     ),
                     pw.Text('Pago: $_paymentMethod', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.blueGrey)),
                  ]
                )
              ],
            ),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            // Resumen Ejecutivo
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                color: PdfColors.grey50
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfStat('Ventas Totales', 'S/ ${totalVentas.toStringAsFixed(2)}', fontBold),
                  _buildPdfStat('Total Pedidos', '$totalPedidos', fontBold),
                  _buildPdfStat('Ticket Promedio', 'S/ ${ticketPromedio.toStringAsFixed(2)}', fontBold),
                ]
              )
            ),
            pw.SizedBox(height: 30),
            
            // 1. Detalle de Ventas
            pw.Header(level: 1, text: '1. Evolución de Ventas', textStyle: pw.TextStyle(font: fontBold, fontSize: 16)),
            pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.orange700),
              cellStyle: pw.TextStyle(font: font, fontSize: 10),
              cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
              headers: ['Fecha', 'Pedidos', 'Total Venta', 'Promedio'],
              data: [
                ..._ventas.map((v) {
                   final venta = double.tryParse(v['total_ventas'].toString()) ?? 0;
                   final pedidos = (v['cantidad_pedidos'] as int?) ?? 0;
                   final prom = pedidos > 0 ? venta / pedidos : 0.0;
                   return [
                    v['fecha'].toString().substring(0, 10),
                    pedidos.toString(),
                    'S/ ${venta.toStringAsFixed(2)}',
                    'S/ ${prom.toStringAsFixed(2)}'
                  ];
                }),
              ],
            ),
            pw.SizedBox(height: 20),

            // 2. Top Platillos
            pw.Header(level: 1, text: '2. Platillos Más Vendidos (Top 10)', textStyle: pw.TextStyle(font: fontBold, fontSize: 16)),
             pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
              cellStyle: pw.TextStyle(font: font, fontSize: 10),
              headers: ['Platillo', 'Unidades Vendidas'],
              data: [
                ..._platillos.map((p) => [
                  p['nombre'].toString(),
                  p['total_vendido'].toString()
                ]),
              ],
            ),
            pw.SizedBox(height: 20),

            // 3. Rendimiento Mozos
            pw.Header(level: 1, text: '3. Rendimiento del Personal', textStyle: pw.TextStyle(font: fontBold, fontSize: 16)),
            pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
              cellStyle: pw.TextStyle(font: font, fontSize: 10),
              headers: ['Colaborador', 'Usuario', 'Pedidos Atendidos', 'Venta Generada'],
              data: [
                ..._mozos.map((m) => [
                  m['nombre'].toString(),
                  m['usuario'].toString(),
                  m['pedidos_tomados'].toString(),
                  'S/ ${double.tryParse(m['total_generado'].toString())?.toStringAsFixed(2) ?? "0.00"}'
                ]),
              ],
            ),
            
            pw.SizedBox(height: 40),
            pw.Center(child: pw.Text('--- Fin del Reporte ---', style: pw.TextStyle(font: font, color: PdfColors.grey500, fontSize: 9)))
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Reporte_EnCrocante_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf'
    );
  }

  pw.Widget _buildPdfStat(String label, String value, pw.Font font) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(font: font, fontSize: 16, color: PdfColors.orange800)),
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      ]
    );
  }

  void _setFilterRange(int type) {
    final now = DateTime.now();
    // Normalize End Date to End of Today (23:59:59)
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    _usePresetToday = false; // Default false

    if (type == 0) {
      // Hoy (Start of Today)
      _startDate = DateTime(now.year, now.month, now.day);
      _filterLabel = "Hoy";
      _usePresetToday = true; // Use server preset
    } else if (type == 7) {
      // Últimos 7 Días (Today included)
      // Start = Today - 6 days (to make 7 days total including today) or -7 for a full week back.
      // Let's use -6 to matching "This Week/Last 7 days" typically including today.
      // Actually standard is often -7 to cover full previous week window. Let's do -6 to include today as 7th day? 
      // User asked for "Esta Semana". If Monday-Sunday is preferred, logic is different.
      // Assuming "Last 7 Days" rolling window:
      _startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      _filterLabel = "Esta Semana";
    } else if (type == 30) {
      // Este Mes
      _startDate = DateTime(now.year, now.month, 1);
      // _endDate is already set to Today End. But "This Month" usually implies up to *now* or full month?
      // "Este Mes" usually means 1st to End of Month. 
      // If we want to show full month range even future days (empty):
      _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      _filterLabel = "Este Mes";
    }
    
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Wrapped in Scaffold to have a FAB or access to context better
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (_ventas.isEmpty && _platillos.isEmpty) ? null : _exportPdf,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("Exportar PDF"),
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // Unified Filter Card
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        // Date Filter Dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Fecha", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              DropdownButton<String>(
                                isExpanded: true,
                                value: _filterLabel == "Personalizado" ? "Personalizado" : _filterLabel,
                                underline: Container(), // Remove underline
                                icon: const Icon(Icons.calendar_today, size: 16),
                                items: ["Hoy", "Esta Semana", "Este Mes", "Personalizado"].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue == "Personalizado") {
                                    _pickDateRange();
                                  } else if (newValue != null) {
                                    int days = 0;
                                    if (newValue == "Hoy") days = 0;
                                    if (newValue == "Esta Semana") days = 7;
                                    if (newValue == "Este Mes") days = 30;
                                    _setFilterRange(days);
                                  }
                                },
                              ),
                              if (_filterLabel == "Personalizado" && _startDate != null && _endDate != null)
                                Text(
                                  "${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}",
                                  style: const TextStyle(fontSize: 10, color: Colors.blue),
                                )
                            ],
                          ),
                        ),
                        
                        Container(width: 1, height: 40, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 16)),

                        // Payment Filter Dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Pago", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              DropdownButton<String>(
                                isExpanded: true,
                                value: _paymentMethod,
                                underline: Container(),
                                icon: const Icon(Icons.payment, size: 16),
                                items: ["Todos", "Efectivo", "Yape - Plin", "Tarjeta"].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _paymentMethod = newValue;
                                    });
                                    _loadData();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(icon: Icon(Icons.show_chart), text: 'Ventas'),
                    Tab(icon: Icon(Icons.pie_chart), text: 'Platillos'),
                    Tab(icon: Icon(Icons.people), text: 'Personal'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _errorMessage != null 
                ? Center(child: Text('Error: $_errorMessage'))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVentasTab(),
                      _buildPlatillosTab(),
                      _buildMozosTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentasTab() {
     if (_ventas.isEmpty) return const Center(child: Text("No hay datos de ventas recientes."));

     // Ordenar por fecha
     _ventas.sort((a, b) => a['fecha'].toString().compareTo(b['fecha'].toString()));

     // Calcular máximo para escala
     double maxY = 0;
     for (var venta in _ventas) {
       double y = double.tryParse(venta['total_ventas'].toString()) ?? 0;
       if (y > maxY) maxY = y;
     }

     // Asegurar valor mínimo para visualización
     if (maxY == 0) maxY = 100;
     double chartMaxY = maxY * 1.3; // 30% buffer superior

     // Crear barras
     List<BarChartGroupData> barGroups = [];
     for (int i = 0; i < _ventas.length; i++) {
       double y = double.tryParse(_ventas[i]['total_ventas'].toString()) ?? 0;
       barGroups.add(
         BarChartGroupData(
           x: i,
           barRods: [
             BarChartRodData(
               toY: y,
               color: Colors.blue,
               width: 22,
               borderRadius: const BorderRadius.only(
                 topLeft: Radius.circular(6),
                 topRight: Radius.circular(6),
               ),
               gradient: LinearGradient(
                 colors: [
                   Colors.blue.shade400,
                   Colors.blue.shade700,
                 ],
                 begin: Alignment.bottomCenter,
                 end: Alignment.topCenter,
               ),
             ),
           ],
           showingTooltipIndicators: [0],
         ),
       );
     }

      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 150), // Increased bottom padding for FAB
        child: Column(
         children: [
           const Text(
             "Ventas Diarias (Últimos 7 días)",
             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
           ),
           const SizedBox(height: 10),
           const Text(
             "Toca las barras para ver detalles",
             style: TextStyle(fontSize: 12, color: Colors.grey),
           ),
           const SizedBox(height: 20),

           // Gráfico de barras - Fixed Height
           SizedBox(
             height: 300,
             child: BarChart(
               BarChartData(
                 maxY: chartMaxY,
                 minY: 0,
                 barGroups: barGroups,
                 gridData: FlGridData(
                   show: true,
                   drawVerticalLine: false,
                   horizontalInterval: chartMaxY / 5,
                   getDrawingHorizontalLine: (value) {
                     return FlLine(
                       color: Colors.grey.withOpacity(0.2),
                       strokeWidth: 1,
                     );
                   },
                 ),
                 titlesData: FlTitlesData(
                   leftTitles: AxisTitles(
                     sideTitles: SideTitles(
                       showTitles: true,
                       reservedSize: 50,
                       interval: chartMaxY / 5,
                       getTitlesWidget: (value, meta) {
                         return Padding(
                           padding: const EdgeInsets.only(right: 8.0),
                           child: Text(
                             'S/${value.toStringAsFixed(0)}',
                             style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                           ),
                         );
                       },
                     ),
                   ),
                   bottomTitles: AxisTitles(
                     sideTitles: SideTitles(
                       showTitles: true,
                       reservedSize: 60,
                       getTitlesWidget: (value, meta) {
                         int index = value.toInt();
                         if (index >= 0 && index < _ventas.length) {
                             try {
                               String dateStr = _ventas[index]['fecha'].toString();
                               DateTime dt = DateTime.parse(dateStr).toLocal();
                               return Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: Column(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   Text(
                                     "${dt.day}",
                                     style: const TextStyle(
                                       fontSize: 12,
                                       fontWeight: FontWeight.bold,
                                     ),
                                   ),
                                   Text(
                                     "${_getMonthAbbr(dt.month)}",
                                     style: TextStyle(
                                       fontSize: 9,
                                       color: Colors.grey[600],
                                     ),
                                   ),
                                 ],
                               ),
                             );
                           } catch (e) {
                             return const SizedBox();
                           }
                         }
                         return const SizedBox();
                       },
                     ),
                   ),
                   topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                   rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                 ),
                 borderData: FlBorderData(
                   show: true,
                   border: Border(
                     left: BorderSide(color: Colors.grey.withOpacity(0.3)),
                     bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
                   ),
                 ),
                 barTouchData: BarTouchData(
                   enabled: true,
                   touchTooltipData: BarTouchTooltipData(
                     tooltipBgColor: Colors.blueGrey.shade700,
                     tooltipRoundedRadius: 8,
                     tooltipPadding: const EdgeInsets.all(8),
                     getTooltipItem: (group, groupIndex, rod, rodIndex) {
                       if (groupIndex >= 0 && groupIndex < _ventas.length) {
                         try {
                           String dateStr = _ventas[groupIndex]['fecha'].toString();
                           DateTime dt = DateTime.parse(dateStr).toLocal();
                           int pedidos = _ventas[groupIndex]['cantidad_pedidos'] ?? 0;
                           return BarTooltipItem(
                             '${dt.day}/${dt.month}/${dt.year}\n',
                             const TextStyle(
                               color: Colors.white,
                               fontWeight: FontWeight.bold,
                               fontSize: 12,
                             ),
                             children: [
                               TextSpan(
                                 text: 'S/ ${rod.toY.toStringAsFixed(2)}\n',
                                 style: const TextStyle(
                                   color: Colors.greenAccent,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 14,
                                 ),
                               ),
                               TextSpan(
                                 text: '$pedidos pedido${pedidos != 1 ? 's' : ''}',
                                 style: const TextStyle(
                                   color: Colors.white70,
                                   fontSize: 11,
                                 ),
                               ),
                             ],
                           );
                         } catch (e) {
                           return null;
                         }
                       }
                       return null;
                     },
                   ),
                 ),
               ),
             ),
           ),

           const SizedBox(height: 10),

           // Lista de detalles debajo del gráfico
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: Colors.grey[100],
               borderRadius: BorderRadius.circular(8),
             ),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceAround,
               children: [
                 _buildStatItem(
                   'Total Ventas',
                   'S/ ${_ventas.fold<double>(0, (sum, v) => sum + (double.tryParse(v['total_ventas'].toString()) ?? 0)).toStringAsFixed(2)}',
                   Icons.attach_money,
                   Colors.green,
                 ),
                 _buildStatItem(
                   'Total Pedidos',
                   '${_ventas.fold<int>(0, (sum, v) => sum + ((v['cantidad_pedidos'] as int?) ?? 0))}',
                   Icons.receipt_long,
                   Colors.orange,
                 ),
                 _buildStatItem(
                   'Promedio/día',
                   'S/ ${(_ventas.fold<double>(0, (sum, v) => sum + (double.tryParse(v['total_ventas'].toString()) ?? 0)) / _ventas.length).toStringAsFixed(2)}',
                   Icons.trending_up,
                   Colors.blue,
                 ),
               ],
             ),
           ),
         ],
       ),
     );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[month - 1];
  }

  Widget _buildPlatillosTab() {
    if (_platillos.isEmpty) return const Center(child: Text("No hay datos de platillos."));

    List<PieChartSectionData> sections = [];
    List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink];

    for (int i = 0; i < _platillos.length; i++) {
       if (i >= 5) break; // Top 5 chart
       double val = double.tryParse(_platillos[i]['total_vendido'].toString()) ?? 0;
       
       if (val > 0) {
         sections.add(PieChartSectionData(
           color: colors[i % colors.length],
           value: val,
           title: '${val.toInt()}',
           radius: 50,
           titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
         ));
       }
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
      child: Column(
        children: [
          const Text("Top 5 Platillos Más Vendidos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          
          // Chart
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // Legend (ListView dentro de ScrollView necesita shrinkWrap y no scroll)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sections.length,
            itemBuilder: (context, index) {
               if (index >= _platillos.length) return const SizedBox();
               return ListTile(
                leading: CircleAvatar(backgroundColor: sections[index].color, radius: 8),
                title: Text(_platillos[index]['nombre'], style: const TextStyle(fontSize: 14)),
                trailing: Text("${_platillos[index]['total_vendido']} un.", style: const TextStyle(fontWeight: FontWeight.bold)),
                dense: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMozosTab() {
    if (_mozos.isEmpty) return const Center(child: Text("No hay datos de personal."));

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _mozos.length,
      padding: const EdgeInsets.only(bottom: 150), // Increased space for FAB
      itemBuilder: (context, index) {
        final m = _mozos[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text(m['nombre'].toString().substring(0, 1).toUpperCase())),
            title: Text(m['nombre']),
            subtitle: Text("Usuario: ${m['usuario']}"),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("S/${double.tryParse(m['total_generado'].toString())?.toStringAsFixed(2) ?? '0.00'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Text("${m['pedidos_tomados']} pedidos", style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }



  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      // Allow future dates so user can pick 'Server Today' even if Device is behind
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null 
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      }
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        // Fix: Set EndDate to end of the selected day (23:59:59)
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        _filterLabel = "Personalizado";
        _usePresetToday = false; // Disable server preset for custom ranges
      });
      _loadData();
    }
  }
}
