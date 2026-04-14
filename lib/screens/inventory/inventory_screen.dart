import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_foodmind/screens/inventory/add_product_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  Future<List> obtenerDespensa() async {
    final response = await http.get(
      Uri.parse('https://yost.es/SM-IT/2025-26/1B/website/mvp/despensa.php'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al cargar datos");
    }
  }

  Future<void> borrarProducto(String id) async {
    final response = await http.post(
      Uri.parse('https://yost.es/SM-IT/2025-26/1B/website/mvp/borrar_despensa.php'),
      body: {"id": id},
    );

    final data = jsonDecode(response.body);

    if (data["ok"] == true) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Producto borrado")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al borrar producto")),
      );
    }
  }

  Future<void> actualizarCantidad(String id, String accion) async {
    final response = await http.post(
      Uri.parse('https://yost.es/SM-IT/2025-26/1B/website/mvp/actualizar_cantidad.php'),
      body: {
        "id": id,
        "accion": accion,
      },
    );

    final data = jsonDecode(response.body);

    if (data["ok"] == true) {
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar cantidad")),
      );
    }
  }

  void confirmarBorrado(String id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Borrar producto"),
        content: Text("¿Seguro que quieres borrar \"$nombre\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              borrarProducto(id);
            },
            child: const Text("Borrar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventario")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
            ),
          );
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: obtenerDespensa(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          final items = snapshot.data as List;

          if (items.isEmpty) {
            return const Center(
              child: Text("No hay productos en el inventario"),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(item['nombre'] ?? 'Sin nombre'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Marca: ${item['marca']}"),
                      Text("Calorías: ${item['calorias']}"),
                      Row(
                        children: [
                          const Text("Cantidad: "),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              actualizarCantidad(
                                item['id'].toString(),
                                'restar',
                              );
                            },
                          ),
                          Text(
                            item['cantidad'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              actualizarCantidad(
                                item['id'].toString(),
                                'sumar',
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      confirmarBorrado(
                        item['id'].toString(),
                        item['nombre'] ?? 'producto',
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}