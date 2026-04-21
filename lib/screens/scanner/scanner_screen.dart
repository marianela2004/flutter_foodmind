import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController scannerController = MobileScannerController();

  final TextEditingController codigoController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController marcaController = TextEditingController();
  final TextEditingController ingredientesController = TextEditingController();
  final TextEditingController caloriasController = TextEditingController();
  final TextEditingController cantidadController =
      TextEditingController(text: '1');

  bool escaneando = true;
  bool cargandoProducto = false;
  bool guardando = false;

  @override
  void dispose() {
    scannerController.dispose();
    codigoController.dispose();
    nombreController.dispose();
    marcaController.dispose();
    ingredientesController.dispose();
    caloriasController.dispose();
    cantidadController.dispose();
    super.dispose();
  }

  Future<void> buscarProductoPorCodigo(String barcode) async {
    if (!mounted) return;

    setState(() {
      cargandoProducto = true;
    });

    codigoController.text = barcode;

    try {
      final response = await http.get(
        Uri.parse('https://world.openfoodfacts.net/api/v2/product/$barcode'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final product = data['product'];

        if (product != null) {
          final nutriments = product['nutriments'] ?? {};

          setState(() {
            nombreController.text = product['product_name'] ?? '';
            marcaController.text = product['brands'] ?? '';
            ingredientesController.text = product['ingredients_text'] ?? '';
            caloriasController.text =
                nutriments['energy-kcal_100g']?.toString() ?? '0';
          });

          if (nombreController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto encontrado, pero sin nombre disponible'),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró información para ese código'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al consultar el producto'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        cargandoProducto = false;
      });
    }
  }

  Future<void> guardarProducto() async {
    if (nombreController.text.trim().isEmpty ||
        cantidadController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa al menos nombre y cantidad'),
        ),
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'https://yost.es/SM-IT/2025-26/1B/website/mvp/insertar_despensa.php',
        ),
        body: {
          'codigo': codigoController.text,
          'nombre': nombreController.text,
          'marca': marcaController.text,
          'ingredientes': ingredientesController.text,
          'calorias':
              caloriasController.text.trim().isEmpty ? '0' : caloriasController.text,
          'cantidad': cantidadController.text,
        },
      );

      if (!mounted) return;

      print('STATUS: ${response.statusCode}');
      print('BODY: ${response.body}');

      final data = jsonDecode(response.body);

      if (data['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto guardado correctamente'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar: ${data['error'] ?? 'desconocido'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red al guardar: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        guardando = false;
      });
    }
  }

  Future<void> onDetect(BarcodeCapture capture) async {
    if (!escaneando) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      escaneando = false;
    });

    await scannerController.stop();
    await buscarProductoPorCodigo(code);
  }

  Future<void> volverAEscanear() async {
    codigoController.clear();
    nombreController.clear();
    marcaController.clear();
    ingredientesController.clear();
    caloriasController.clear();
    cantidadController.text = '1';

    setState(() {
      escaneando = true;
      cargandoProducto = false;
    });

    await scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear y añadir producto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => scannerController.switchCamera(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (escaneando)
              SizedBox(
                height: 300,
                child: MobileScanner(
                  controller: scannerController,
                  onDetect: onDetect,
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                alignment: Alignment.center,
                color: Colors.grey.shade200,
                child: const Text(
                  'Código escaneado',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: codigoController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Código de barras',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: marcaController,
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ingredientesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Ingredientes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: caloriasController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calorías',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cantidadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (cargandoProducto) const CircularProgressIndicator(),
                  if (!cargandoProducto) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: guardando ? null : guardarProducto,
                        child: guardando
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Guardar producto'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: volverAEscanear,
                        child: const Text('Escanear otro'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}