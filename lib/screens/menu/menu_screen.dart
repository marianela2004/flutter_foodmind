import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool loading = true;
  Map<String, dynamic> sugerencias = {};
  Set<String> favoritos = {}; // 🔥 clave: tipo+texto

  @override
  void initState() {
    super.initState();
    cargarMenu();
    cargarFavoritos();
  }

  Future<void> cargarMenu() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id') ?? 0;

    final url = Uri.parse(
      "https://yost.es/SM-IT/2025-26/1B/website/mvp/calendario_recetas.php",
    );

    final response = await http.post(url, body: {
      "usuario_id": usuarioId.toString(),
    });

    if (response.statusCode == 200) {
      setState(() {
        sugerencias = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> cargarFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id') ?? 0;

    final url = Uri.parse(
      "https://yost.es/SM-IT/2025-26/1B/website/mvp/get_favoritos_menu.php",
    );

    final res = await http.post(url, body: {
      "usuario_id": usuarioId.toString(),
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["ok"]) {
        setState(() {
          favoritos = (data["favoritos"] as List)
              .map((e) => "${e['tipo']}|${e['texto']}")
              .toSet();
        });
      }
    }
  }

  Future<void> toggleFavorito(String tipo, String texto) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id') ?? 0;

    final key = "$tipo|$texto";
    final isFav = favoritos.contains(key);

    final url = Uri.parse(
      "https://yost.es/SM-IT/2025-26/1B/website/mvp/favorito_menu.php",
    );

    await http.post(url, body: {
      "usuario_id": usuarioId.toString(),
      "tipo": tipo,
      "texto": texto,
      "accion": isFav ? "0" : "1",
    });

    setState(() {
      if (isFav) {
        favoritos.remove(key);
      } else {
        favoritos.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF527d5a);
    const crema = Color(0xFFe9ddd4);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      appBar: AppBar(
        title: const Text("Menú diario",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: verde)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: verde))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                children: [
                  _cardComida("desayuno", "Desayuno",
                      sugerencias["desayuno"] ?? "No disponible"),
                  _cardComida("comida", "Comida",
                      sugerencias["comida"] ?? "No disponible"),
                  _cardComida("merienda", "Merienda",
                      sugerencias["merienda"] ?? "No disponible"),
                  _cardComida("cena", "Cena",
                      sugerencias["cena"] ?? "No disponible"),
                ],
              ),
            ),
    );
  }

  Widget _cardComida(String tipo, String titulo, String texto) {
    const verde = Color(0xFF527d5a);
    const crema = Color(0xFFe9ddd4);

    final key = "$tipo|$texto";
    final isFav = favoritos.contains(key);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: crema, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(_icon(tipo), color: verde, size: 30),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: verde)),
                const SizedBox(height: 8),
                Text(texto),
              ],
            ),
          ),

          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : verde,
            ),
            onPressed: () => toggleFavorito(tipo, texto),
          )
        ],
      ),
    );
  }

  IconData _icon(String tipo) {
    switch (tipo) {
      case "desayuno":
        return Icons.free_breakfast;
      case "comida":
        return Icons.restaurant;
      case "merienda":
        return Icons.cookie;
      default:
        return Icons.nightlight_round;
    }
  }
}