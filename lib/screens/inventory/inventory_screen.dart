import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_product_screen.dart'; // 👈 IMPORTANTE

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {

  // 🔥 Función para obtener datos de tu API
  Future<List> obtenerDespensa() async {
    final response = await http.get(
      Uri.parse('https://yost.es/SM-IT/2025-26/1B/website/mvp/despensa.php'),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al cargar datos");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventario")),

      // ➕ BOTÓN AÑADIR
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
            ),
          );

          // 🔄 refresca al volver
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),

      body: FutureBuilder(
        future: obtenerDespensa(),
        builder: (context, snapshot) {

          // 🔄 Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ Error
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          final items = snapshot.data as List;

          // 📦 Lista de productos
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(item['nombre'] ?? 'Sin nombre'),
                  subtitle: Text(
                    "Marca: ${item['marca']} \nCantidad: ${item['cantidad']} \nCalorías: ${item['calorias']}"
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}