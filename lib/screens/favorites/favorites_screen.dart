import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {

  static const verde = Color(0xFF527d5a);
  static const crema = Color(0xFFe9ddd4);
  static const fondo = Color(0xFFF8F6F2);

  bool loading = true;
  String filtro = "desayuno";

  Map<String, List<Map>> favoritosPorTipo = {
    "desayuno": [],
    "comida": [],
    "merienda": [],
    "cena": [],
  };

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Map convertirReceta(String texto) {
    try {
      texto = texto.substring(1, texto.length - 1);
      final partes = texto.split(", pasos:");
      final tituloParte = partes[0].replaceFirst("titulo:", "").trim();
      final pasosParte = partes[1].replaceAll("[", "").replaceAll("]", "").trim();
      List<String> pasos = pasosParte.split(",");
      pasos = pasos.map((e) => e.trim()).toList();
      return {"titulo": tituloParte, "pasos": pasos};
    } catch (e) {
      return {"titulo": texto, "pasos": ["No se pudo leer la receta"]};
    }
  }

  Future<void> eliminarFavorito(String tipo, String textoOriginal) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id') ?? 0;

    final url = Uri.parse("https://yost.es/SM-IT/2025-26/1B/website/mvp/favorito_menu.php");

    await http.post(url, body: {
      "usuario_id": usuarioId.toString(),
      "tipo": tipo,
      "texto": textoOriginal,
      "accion": "0",
    });

    cargar();
  }

  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id') ?? 0;

    final url = Uri.parse("https://yost.es/SM-IT/2025-26/1B/website/mvp/get_favoritos_menu.php");

    final res = await http.post(url, body: {
      "usuario_id": usuarioId.toString(),
    });

    final data = jsonDecode(res.body);
    final lista = data["favoritos"] ?? [];

    Map<String, List<Map>> agrupados = {
      "desayuno": [],
      "comida": [],
      "merienda": [],
      "cena": [],
    };

    for (var fav in lista) {
      final tipo = fav["tipo"];
      final receta = convertirReceta(fav["texto"]);
      receta["textoOriginal"] = fav["texto"];
      agrupados[tipo]?.add(receta);
    }

    setState(() {
      favoritosPorTipo = agrupados;
      loading = false;
    });
  }

  void mostrarDetalleReceta(Map receta) {
    final pasos = receta["pasos"];

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(receta["titulo"],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: verde)),
              const SizedBox(height: 16),
              ...List.generate(
                pasos.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text("Paso ${i + 1}: ${pasos[i]}"),
                ),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar"))
            ],
          ),
        ),
      ),
    );
  }

  Widget chip(String tipo, IconData icono) {
    final seleccionado = filtro == tipo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => setState(() => filtro = tipo),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: seleccionado ? verde : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: seleccionado ? verde : crema),
          ),
          child: Row(
            children: [
              Icon(icono, size: 18, color: seleccionado ? Colors.white : verde),
              const SizedBox(width: 6),
              Text(
                tipo.toUpperCase(),
                style: TextStyle(
                  color: seleccionado ? Colors.white : verde,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget cardReceta(String tipo, Map receta) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: crema),
      ),
      child: ListTile(
        title: Text(receta["titulo"]),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          onPressed: () => eliminarFavorito(tipo, receta["textoOriginal"]),
        ),
        onTap: () => mostrarDetalleReceta(receta),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = favoritosPorTipo[filtro]!;

    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        title: const Text(
          "Favoritos",
          style: TextStyle(
            color: verde,
            fontWeight: FontWeight.bold, 
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: verde),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 20),

                /// ⭐ CHIPS DESLIZABLES
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      chip("desayuno", Icons.free_breakfast),
                      chip("comida", Icons.restaurant),
                      chip("merienda", Icons.cookie),
                      chip("cena", Icons.nightlight_round),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (lista.isEmpty)
                  const Center(child: Text("No tienes recetas guardadas aún ❤️")),

                ...lista.map((r) => cardReceta(filtro, r)),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}