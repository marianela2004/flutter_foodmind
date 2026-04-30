import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../onboarding/pack_screen.dart';
import '../onboarding/diet_screen.dart';
import '../onboarding/allergies_screen.dart';
import '../onboarding/dislikes_screen.dart';
import '../../widgets/primary_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String nombre = '';
  String pack = '';
  String dieta = '';
  List<String> alergias = [];
  List<String> dislikes = [];

  bool editingNombre = false;

  final TextEditingController nombreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      nombre = prefs.getString('nombre_usuario') ?? '';
      pack = prefs.getString('numero_pack') ?? '';
      dieta = prefs.getString('dieta_usuario') ?? '';
      alergias = List<String>.from(
          jsonDecode(prefs.getString('alergias_usuario') ?? '[]'));
      dislikes = List<String>.from(
          jsonDecode(prefs.getString('dislikes_usuario') ?? '[]'));

      nombreController.text = nombre;
    });
  }

  Future<void> guardarEnServidor() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');

    await http.post(
      Uri.parse(
          'https://yost.es/SM-IT/2025-26/1B/website/mvp/guardar_usuario.php'),
      body: {
        'usuario_id': usuarioId.toString(),
        'nombre': nombre,
        'numero_pack': pack,
        'tipo_dieta': dieta,
        'alergias': jsonEncode(alergias),
        'no_gustan': jsonEncode(dislikes),
      },
    );
  }

  // ⭐ FORMATEAR DIETA
  String formatearDieta(String dietaRaw) {
    if (dietaRaw.trim().isEmpty) return 'No configurado';

    try {
      final data = jsonDecode(dietaRaw);

      if (data is Map) {
        final opciones = data['opciones'];
        final detalle = data['detalle']?.toString().trim() ?? '';

        final opcionesTexto =
            opciones is List && opciones.isNotEmpty ? opciones.join(', ') : '';

        if (opcionesTexto.isNotEmpty && detalle.isNotEmpty) {
          return '$opcionesTexto\n$detalle';
        }

        if (opcionesTexto.isNotEmpty) return opcionesTexto;
        if (detalle.isNotEmpty) return detalle;
      }

      if (data is List) return data.join(', ');
    } catch (_) {}

    return dietaRaw;
  }

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF527d5a);
    const crema = Color(0xFFe9ddd4);
    const beige = Color(0xFFd2b08b);
    const mostaza = Color(0xFFf1b810);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Ajustes",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: verde,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            // ICONO
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: crema,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: mostaza,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: beige,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const Icon(Icons.settings_rounded, size: 42, color: verde),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // NOMBRE
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: crema, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nombre",
                      style:
                          TextStyle(color: verde, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nombreController,
                          enabled: editingNombre,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: crema.withOpacity(0.55),
                            prefixIcon:
                                const Icon(Icons.person, color: verde),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (v) => nombre = v,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (!editingNombre) {
                            setState(() => editingNombre = true);
                            return;
                          }

                          final prefs =
                              await SharedPreferences.getInstance();
                          await prefs.setString('nombre_usuario', nombre);
                          await guardarEnServidor();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Nombre guardado")),
                          );

                          setState(() => editingNombre = false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: verde,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(editingNombre ? "Guardar" : "Editar"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // PACK (NO EDITABLE)
            _tile(
              titulo: "Código pack",
              valor: pack,
              icono: Icons.qr_code_2_rounded,
              editable: false,
              onTap: () {},
            ),

            // DIETA (FORMATEADA)
            _tile(
              titulo: "Dieta",
              valor: formatearDieta(dieta),
              icono: Icons.eco_rounded,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DietScreen(
                      numeroPack: pack,
                      editingFromSettings: true,
                    ),
                  ),
                );
                cargarDatos();
                guardarEnServidor();
              },
            ),

            _tile(
              titulo: "Alergias",
              valor: alergias.join(", "),
              icono: Icons.health_and_safety_rounded,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllergiesScreen(
                      numeroPack: pack,
                      diet: dieta,
                      editingFromSettings: true,
                    ),
                  ),
                );
                cargarDatos();
                guardarEnServidor();
              },
            ),

            _tile(
              titulo: "Productos que no gustan",
              valor: dislikes.join(", "),
              icono: Icons.thumb_down_alt_rounded,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DislikesScreen(
                      numeroPack: pack,
                      diet: dieta,
                      allergies: alergias,
                      editingFromSettings: true,
                    ),
                  ),
                );
                cargarDatos();
                guardarEnServidor();
              },
            ),
          ],
        ),
      ),
    );
  }

  // TILE MODIFICADO
  Widget _tile({
    required String titulo,
    required String valor,
    required IconData icono,
    required VoidCallback onTap,
    bool editable = true,
  }) {
    const verde = Color(0xFF527d5a);
    const crema = Color(0xFFe9ddd4);

    return GestureDetector(
      onTap: editable ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: crema, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icono, color: verde, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: verde,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    valor.isEmpty ? "No configurado" : valor,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            if (editable)
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: verde),
          ],
        ),
      ),
    );
  }
}