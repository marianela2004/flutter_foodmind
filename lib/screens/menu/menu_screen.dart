import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../chatbot/chatbot.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool loading = true;
  Map<String, dynamic> sugerencias = {};
  Set<String> favoritos = {};

  @override
  void initState() {
    super.initState();
    cargarMenu();
    cargarFavoritos();
  }

  // =========================
  // 📡 MENU
  // =========================
  Future<void> cargarMenu() async {
    final prefs = await SharedPreferences.getInstance();
    final cache = prefs.getString("menu_cache");

    if (cache != null) {
      sugerencias = jsonDecode(cache);
      setState(() => loading = false);
      return;
    }

    final usuarioId = prefs.getInt('usuario_id') ?? 0;

    final url = Uri.parse(
      "https://yost.es/SM-IT/2025-26/1B/website/mvp/calendario_recetas.php",
    );

    final response = await http.post(url, body: {
      "usuario_id": usuarioId.toString(),
    });

    if (response.statusCode == 200) {
      sugerencias = jsonDecode(response.body);

      await prefs.setString("menu_cache", jsonEncode(sugerencias));
    }

    setState(() => loading = false);
  }

  // =========================
  // ⭐ FAVORITOS
  // =========================
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
      isFav ? favoritos.remove(key) : favoritos.add(key);
    });
  }

  // =========================
  // 🧠 PARSER SEGURO
  // =========================
  Map parseReceta(dynamic data) {
    if (data is Map) {
      return {
        "titulo": data["titulo"] ?? "",
        "pasos": List<String>.from(data["pasos"] ?? [])
      };
    }

    return {
      "titulo": data.toString(),
      "pasos": []
    };
  }

  // =========================
  // 🍽️ POPUP (TU DISEÑO RESTAURADO)
  // =========================
  void mostrarDetalleReceta(String tipo, Map receta) {
    const verde = Color(0xFF527d5a);
    const crema = Color(0xFFe9ddd4);
    const mostaza = Color(0xFFD4A373);
    const marron = Color(0xFF6A4E3B);

    final titulo = receta["titulo"] ?? "";
    final pasos = receta["pasos"] ?? [];

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // 🔥 TU TÍTULO
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: verde,
                ),
              ),

              const SizedBox(height: 18),

              // 🔥 PASOS
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: crema.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(pasos.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        "Paso ${i + 1}: ${pasos[i]}",
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.4,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 16),

              // 🔥 CONSEJO
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: mostaza.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 18, color: marron),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Sigue los pasos en orden y adapta cantidades según necesidad.",
                        style: TextStyle(
                          fontSize: 13,
                          color: marron,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cerrar",
                    style: TextStyle(color: verde),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // 🧾 UI
  // =========================
  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF527d5a);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),

      appBar: AppBar(
        title: const Text(
          "Menú diario",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: verde,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.3),
                  builder: (_) => const Chatbot(),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: verde, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundImage: AssetImage('assets/images/cocinia.png'),
                ),
              ),
            ),
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                children: [
                  _card("desayuno", "Desayuno"),
                  _card("comida", "Comida"),
                  _card("merienda", "Merienda"),
                  _card("cena", "Cena"),
                ],
              ),
            ),
    );
  }

  // =========================
  // 🍽️ CARD
  // =========================
  Widget _card(String tipo, String titulo) {
    const verde = Color(0xFF527d5a);
    const crema = Color(0xFFe9ddd4);

    final data = sugerencias[tipo];
    if (data == null) return const SizedBox();

    final receta = parseReceta(data);

    final key = "$tipo|${receta.toString()}";
    final isFav = favoritos.contains(key);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: crema),
      ),
      child: Row(
        children: [

          Icon(_icon(tipo), color: verde),
          const SizedBox(width: 16),

          Expanded(
            child: InkWell(
              onTap: () => mostrarDetalleReceta(tipo, receta),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: verde,
                    ),
                  ),
                  Text(receta["titulo"].toString()),
                ],
              ),
            ),
          ),

          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : verde,
            ),
            onPressed: () => toggleFavorito(tipo, receta.toString()),
          ),
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