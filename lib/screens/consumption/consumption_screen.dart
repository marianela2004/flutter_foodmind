import 'dart:convert';
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

  static const Color verde = Color(0xFF527d5a);
  static const Color crema = Color(0xFFe9ddd4);
  static const Color fondo = Color(0xFFF8F6F2);

  @override
  void initState() {
    super.initState();
    _futureReporte = obtenerReporte();
  }

  Future<Map<String, dynamic>> obtenerReporte() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');

    if (usuarioId == null) {
      throw Exception("No se encontró el usuario actual");
    }

    final response = await http.post(
      Uri.parse(
        'https://yost.es/SM-IT/2025-26/1B/website/mvp/reporte_consumo.php',
      ),
      body: {
        'usuario_id': usuarioId.toString(),
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['ok'] == true) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(data['error'] ?? "Error al cargar datos");
  }

  Future<void> recargarReporte() async {
    setState(() {
      _futureReporte = obtenerReporte();
    });
    await _futureReporte;
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
        title: const Text(
          "Seguimiento",
          style: TextStyle(
            color: verde,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: verde),
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
            final rapido = List.from(data['consumo_rapido'] ?? []);
            final lento = List.from(data['consumo_lento'] ?? []);
            final recomendacion =
                data['recomendacion']?.toString() ??
                    "Aún no hay suficientes datos para generar recomendaciones.";

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 14),

                _card(
                  "Resumen",
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Productos registrados: ${resumen['total_productos'] ?? 0}"),
                      const SizedBox(height: 6),
                      Text("En inventario: ${resumen['productos_activos'] ?? 0}"),
                      const SizedBox(height: 6),
                      Text("Consumidos: ${resumen['productos_consumidos'] ?? 0}"),
                    ],
                  ),
                ),

                _card(
                  "Más comprados",
                  _lista(masComprados, "nombre", "veces", "veces"),
                ),

                _card(
                  "Consumo rápido",
                  _lista(rapido, "nombre", "dias_medios", "días"),
                ),

                _card(
                  "Consumo lento",
                  _lista(lento, "nombre", "dias_medios", "días"),
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