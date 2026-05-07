import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConsumptionScreen extends StatefulWidget {
  const ConsumptionScreen({super.key});

  @override
  State<ConsumptionScreen> createState() => _ConsumptionScreenState();
}

class _ConsumptionScreenState extends State<ConsumptionScreen> {
  late Future<Map<String, dynamic>> _futureReporte;

  String _filtroActual = 'todo';
  DateTime? _fechaSeleccionada;

  static const Color verde = Color(0xFF527d5a);
  static const Color crema = Color(0xFFe9ddd4);
  static const Color fondo = Color(0xFFF8F6F2);

  @override
  void initState() {
    super.initState();
    _futureReporte = obtenerReporte(
      filtro: _filtroActual,
      fecha: _fechaSeleccionada,
    );
  }

  Future<Map<String, dynamic>> obtenerReporte({
    required String filtro,
    DateTime? fecha,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');

    if (usuarioId == null) {
      throw Exception("No se encontró el usuario actual");
    }

    final body = {
      'usuario_id': usuarioId.toString(),
      'filtro': filtro,
    };

    if (fecha != null) {
      body['fecha'] = _formatearFechaApi(fecha);
    }

    final response = await http.post(
      Uri.parse(
        'https://yost.es/SM-IT/2025-26/1B/website/mvp/reporte_consumo.php',
      ),
      body: body,
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['ok'] == true) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(data['error'] ?? "Error al cargar datos");
  }

  Future<void> recargarReporte() async {
    setState(() {
      _futureReporte = obtenerReporte(
        filtro: _filtroActual,
        fecha: _fechaSeleccionada,
      );
    });

    await _futureReporte;
  }

  void _cambiarFiltro(String filtro) {
    setState(() {
      _filtroActual = filtro;

      if (filtro != 'fecha') {
        _fechaSeleccionada = null;
      }

      _futureReporte = obtenerReporte(
        filtro: _filtroActual,
        fecha: _fechaSeleccionada,
      );
    });
  }

  Future<void> _elegirFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: verde,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha == null) return;

    setState(() {
      _filtroActual = 'fecha';
      _fechaSeleccionada = fecha;
      _futureReporte = obtenerReporte(
        filtro: _filtroActual,
        fecha: _fechaSeleccionada,
      );
    });
  }

  String _formatearFechaApi(DateTime fecha) {
    return "${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
  }

  String _formatearFechaVista(DateTime fecha) {
    return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";
  }

  Widget _filtros() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _botonFiltro(
              texto: "Todo",
              filtro: "todo",
              icono: Icons.all_inclusive_rounded,
            ),
            const SizedBox(width: 8),
            _botonFiltro(
              texto: "Última semana",
              filtro: "semana",
              icono: Icons.calendar_view_week_rounded,
            ),
            const SizedBox(width: 8),
            _botonFiltro(
              texto: "Último mes",
              filtro: "mes",
              icono: Icons.calendar_month_rounded,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _elegirFecha,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _filtroActual == 'fecha' ? verde : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _filtroActual == 'fecha' ? verde : crema,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      size: 18,
                      color: _filtroActual == 'fecha' ? Colors.white : verde,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fechaSeleccionada == null
                          ? "Fecha"
                          : _formatearFechaVista(_fechaSeleccionada!),
                      style: TextStyle(
                        color:
                            _filtroActual == 'fecha' ? Colors.white : verde,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonFiltro({
    required String texto,
    required String filtro,
    required IconData icono,
  }) {
    final seleccionado = _filtroActual == filtro;

    return GestureDetector(
      onTap: () => _cambiarFiltro(filtro),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? verde : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: seleccionado ? verde : crema,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icono,
              size: 18,
              color: seleccionado ? Colors.white : verde,
            ),
            const SizedBox(width: 6),
            Text(
              texto,
              style: TextStyle(
                color: seleccionado ? Colors.white : verde,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String titulo, Widget contenido) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: crema),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: verde,
            ),
          ),
          const SizedBox(height: 12),
          contenido,
        ],
      ),
    );
  }

  Widget _lista(List lista, String campo, String valorCampo, String sufijo) {
    if (lista.isEmpty) {
      return const Text(
        "Sin datos suficientes todavía",
        style: TextStyle(color: Colors.black54),
      );
    }

    return Column(
      children: lista.map((e) {
        final item = Map<String, dynamic>.from(e);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item[campo]?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                "${item[valorCampo] ?? 0} $sufijo",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: verde,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _recomendacion(String texto) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: verde.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          height: 1.45,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3F6547),
        ),
      ),
    );
  }

  Widget _insightsCompra(List lista) {
    if (lista.isEmpty) {
      return const Text(
        "Todavía no hay consejos de compra importantes.",
        style: TextStyle(color: Colors.black54),
      );
    }

    final widgets = <Widget>[];

    for (final e in lista) {
      final item = Map<String, dynamic>.from(e);

      final nombre = item['nombre']?.toString() ?? 'Producto';
      final compras = _toInt(item['compras']);
      final caducados = _toInt(item['caducados']);
      final consumidos = _toInt(item['consumidos']);

      final mensaje = item['mensaje']?.toString() ??
          _generarMensajeInsight(
            nombre: nombre,
            compras: compras,
            caducados: caducados,
            consumidos: consumidos,
          );

      final textoLower = mensaje.toLowerCase();

      final sinDatos = textoLower.contains('no hay suficientes datos') ||
          textoLower.contains('todavía no hay suficientes datos') ||
          textoLower.contains('cuando haya más datos');

      final problema = caducados > 0;

      if (sinDatos || !problema) {
        continue;
      }

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.withOpacity(0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade400,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mensaje,
                  style: const TextStyle(
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F3F3F),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      return const Text(
        "No hay avisos importantes por ahora.",
        style: TextStyle(color: Colors.black54),
      );
    }

    return Column(children: widgets);
  }

  String _generarMensajeInsight({
    required String nombre,
    required int compras,
    required int caducados,
    required int consumidos,
  }) {
    if (caducados > 0) {
      return "Has comprado $nombre $compras veces y se te ha caducado $caducados. Compra menos cantidad o intenta consumirlo antes.";
    }

    if (consumidos > 0) {
      return "Sueles consumir bien $nombre. Puedes mantener tu cantidad habitual.";
    }

    return "Has comprado $nombre $compras veces. Cuando haya más datos, podremos darte una recomendación mejor.";
  }

  Widget _graficoComprasCaducados(List lista) {
    if (lista.isEmpty) {
      return const Text(
        "Aún no hay datos suficientes para mostrar el gráfico.",
        style: TextStyle(color: Colors.black54),
      );
    }

    final items = lista.take(5).map((e) {
      return Map<String, dynamic>.from(e);
    }).toList();

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calcularMaxY(items),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = items[group.x.toInt()];
                final nombre = item['nombre']?.toString() ?? '';
                final label = rodIndex == 0 ? 'Comprado' : 'Caducado';

                return BarTooltipItem(
                  "$nombre\n$label: ${rod.toY.toInt()}",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index < 0 || index >= items.length) {
                    return const SizedBox.shrink();
                  }

                  final nombre = items[index]['nombre']?.toString() ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      nombre.length > 8
                          ? '${nombre.substring(0, 8)}…'
                          : nombre,
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(items.length, (index) {
            final compras = _toDouble(items[index]['compras']);
            final caducados = _toDouble(items[index]['caducados']);

            return BarChartGroupData(
              x: index,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: compras,
                  width: 10,
                  borderRadius: BorderRadius.circular(6),
                  color: verde,
                ),
                BarChartRodData(
                  toY: caducados,
                  width: 10,
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.red.shade300,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _leyendaGrafico() {
    return Row(
      children: [
        _itemLeyenda(verde, "Comprado"),
        const SizedBox(width: 18),
        _itemLeyenda(Colors.red.shade300, "Caducado"),
      ],
    );
  }

  Widget _itemLeyenda(Color color, String texto) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  double _calcularMaxY(List<Map<String, dynamic>> items) {
    double maxValue = 1;

    for (final item in items) {
      final compras = _toDouble(item['compras']);
      final caducados = _toDouble(item['caducados']);

      maxValue = max(maxValue, compras);
      maxValue = max(maxValue, caducados);
    }

    return maxValue + 1;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value.toDouble();

    if (value is double) return value;

    return double.tryParse(value.toString()) ?? 0;
  }

  Widget _error(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
  automaticallyImplyLeading: true,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: verde),
    onPressed: () => Navigator.pop(context),
  ),
  title: const Text(
    "Seguimiento",
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: verde,
    ),
  ),
  backgroundColor: Colors.transparent,
  elevation: 0,
  scrolledUnderElevation: 0,
  centerTitle: true,
  actions: [
    IconButton(
      tooltip: 'Recargar',
      onPressed: recargarReporte,
      icon: const Icon(Icons.refresh_rounded, color: verde),
    ),
  ],
),
      body: RefreshIndicator(
        color: verde,
        onRefresh: recargarReporte,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _futureReporte,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(child: CircularProgressIndicator(color: verde)),
                ],
              );
            }

            if (snapshot.hasError) {
              return _error(snapshot.error!);
            }

            final data = snapshot.data ?? {};

            final resumen = Map<String, dynamic>.from(data['resumen'] ?? {});
            final masComprados = List.from(data['mas_comprados'] ?? []);

            final insights = List.from(
              data['insights'] ??
                  data['consejos_compra'] ??
                  data['consumo_productos'] ??
                  [],
            );

            final recomendacion =
                data['recomendacion']?.toString() ??
                    "Aún no hay suficientes datos para generar recomendaciones.";

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 14),
                _filtros(),
                _card(
                  "Resumen",
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Productos registrados: ${resumen['total_productos'] ?? 0}",
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "En inventario: ${resumen['productos_activos'] ?? 0}",
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Consumidos: ${resumen['productos_consumidos'] ?? 0}",
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Caducados: ${resumen['productos_caducados'] ?? 0}",
                      ),
                    ],
                  ),
                ),
                _card(
                  "Consejos de compra",
                  _insightsCompra(insights),
                ),
                _card(
                  "Compras vs caducados",
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _leyendaGrafico(),
                      const SizedBox(height: 16),
                      _graficoComprasCaducados(insights),
                    ],
                  ),
                ),
                _card(
                  "Más comprados",
                  _lista(masComprados, "nombre", "veces", "veces"),
                ),
                _card(
                  "💡 Recomendación inteligente",
                  _recomendacion(recomendacion),
                ),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }
}