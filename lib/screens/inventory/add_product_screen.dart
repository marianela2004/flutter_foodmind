import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController marcaController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();

  bool cargando = false;

  Future<void> guardarProducto() async {
    setState(() {
      cargando = true;
    });

    final response = await http.post(
      Uri.parse('https://yost.es/SM-IT/2025-26/1B/website/mvp/insertar_despensa.php'),
      body: {
        "nombre": nombreController.text,
        "marca": marcaController.text,
        "cantidad": cantidadController.text,
      },
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    final data = jsonDecode(response.body);

    setState(() {
      cargando = false;
    });

    if (data["ok"] == true) {
      Navigator.pop(context); // vuelve atrás
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar producto")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Añadir producto")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),

            TextField(
              controller: marcaController,
              decoration: const InputDecoration(labelText: "Marca"),
            ),

            TextField(
              controller: cantidadController,
              decoration: const InputDecoration(labelText: "Cantidad"),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            cargando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: guardarProducto,
                    child: const Text("Guardar"),
                  ),
          ],
        ),
      ),
    );
  }
}