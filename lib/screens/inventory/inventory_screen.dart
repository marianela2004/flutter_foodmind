import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foodmind/screens/inventory/add_product_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  Future<List> obtenerDespensa() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');
    final numeroPack = prefs.getString('numero_pack');

    print('USUARIO_ID ACTUAL: $usuarioId');
    print('NUMERO_PACK ACTUAL: $numeroPack');

    if (usuarioId == null) {
      throw Exception("No se encontró el usuario actual");
    }

    final response = await http.post(
      Uri.parse('https://yost.es/SM-IT/2025-26/1B/website/mvp/despensa.php'),
      body: {
        'usuario_id': usuarioId.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      if (data is Map && data['ok'] == true && data['productos'] != null) {
        return data['productos'];
      }

      throw Exception("Formato de respuesta no válido");
    } else {
      throw Exception("Error al cargar datos");
    }
  }

  Future<void> borrarProducto(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');

    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se encontró el usuario actual")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://yost.es/SM-IT/2025-26/1B/website/mvp/borrar_despensa.php'),
      body: {
        "id": id,
        "usuario_id": usuarioId.toString(),
      },
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

  Future<void> cambiarFavorito(String id, int favorito) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');

    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se encontró el usuario actual")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://yost.es/SM-IT/2025-26/1B/website/mvp/favorito_despensa.php'),
      body: {
        "id": id,
        "favorito": favorito.toString(),
        "usuario_id": usuarioId.toString(),
      },
    );

    final data = jsonDecode(response.body);

    if (data["ok"] == true) {
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar favorito")),
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

  Color obtenerColorCaducidad(String estado) {
    switch (estado) {
      case 'rojo':
        return Colors.red;
      case 'amarillo':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String obtenerTextoCaducidad(String estado) {
    switch (estado) {
      case 'rojo':
        return 'Caducado';
      case 'amarillo':
        return 'Consumir pronto';
      default:
        return 'Fresco';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Inventario"),
        ),
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
        body: FutureBuilder<List>(
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

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return const Center(
                child: Text("No hay productos en el inventario"),
              );
            }

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final esFavorito = item['favorito'].toString() == '1';
                final estadoCaducidad =
                    item['estado_caducidad']?.toString() ?? 'verde';
                final colorCaducidad =
                    obtenerColorCaducidad(estadoCaducidad);
                final textoCaducidad =
                    obtenerTextoCaducidad(estadoCaducidad);

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(item['nombre'] ?? 'Sin nombre'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Marca: ${item['marca'] ?? ''}"),
                        Text("Cantidad: ${item['cantidad'] ?? ''}"),
                        Text("Calorías: ${item['calorias'] ?? ''}"),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colorCaducidad,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              textoCaducidad,
                              style: TextStyle(
                                color: colorCaducidad,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    leading: IconButton(
                      icon: Icon(
                        esFavorito ? Icons.favorite : Icons.favorite_border,
                        color: esFavorito ? Colors.red : null,
                      ),
                      onPressed: () {
                        cambiarFavorito(
                          item['id'].toString(),
                          esFavorito ? 0 : 1,
                        );
                      },
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
      ),
    );
  }
}