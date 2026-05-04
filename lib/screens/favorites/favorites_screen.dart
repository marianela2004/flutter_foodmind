import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List favoritos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
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
      setState(() {
        favoritos = data["favoritos"] ?? [];
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF527d5a);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      appBar: AppBar(
        title: const Text("Favoritos",
            style: TextStyle(color: verde)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: verde))
          : favoritos.isEmpty
              ? const Center(child: Text("No tienes favoritos aún"))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: favoritos.length,
                  itemBuilder: (_, i) {
                    final item = favoritos[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        "${item['tipo']}: ${item['texto']}",
                      ),
                    );
                  },
                ),
    );
  }
}