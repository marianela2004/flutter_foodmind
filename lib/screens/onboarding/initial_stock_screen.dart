import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/primary_button.dart';
import '../home/home_screen.dart';

class InitialStockScreen extends StatefulWidget {
  final String numeroPack;
  final String diet;
  final List<String> allergies;
  final List<String> dislikes;

  const InitialStockScreen({
    super.key,
    required this.numeroPack,
    required this.diet,
    required this.allergies,
    required this.dislikes,
  });

  @override
  State<InitialStockScreen> createState() => _InitialStockScreenState();
}

class _InitialStockScreenState extends State<InitialStockScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController marcaController = TextEditingController();
  final TextEditingController cantidadController =
      TextEditingController(text: '1');

  final List<Map<String, dynamic>> initialStock = [];
  bool cargando = false;

  @override
  void dispose() {
    nombreController.dispose();
    marcaController.dispose();
    cantidadController.dispose();
    super.dispose();
  }

  void anadirAlimento() {
    final nombre = nombreController.text.trim();
    final marca = marcaController.text.trim();
    final cantidad = int.tryParse(cantidadController.text.trim()) ?? 1;

    if (nombre.isEmpty) return;

    setState(() {
      initialStock.add({
        'nombre': nombre,
        'marca': marca,
        'cantidad': cantidad <= 0 ? 1 : cantidad,
      });

      nombreController.clear();
      marcaController.clear();
      cantidadController.text = '1';
    });
  }

  Future<int?> guardarUsuarioYObtenerId() async {
    final response = await http.post(
      Uri.parse(
        'https://yost.es/SM-IT/2025-26/1B/website/mvp/guardar_usuario.php',
      ),
      body: {
        'numero_pack': widget.numeroPack,
        'tipo_dieta': widget.diet,
        'alergias': widget.allergies.join(','),
        'no_gustan': widget.dislikes.join(','),
      },
    );

    final data = jsonDecode(response.body);

    if (data['ok'] == true) {
      return int.tryParse(data['usuario_id'].toString());
    }

    throw Exception(data['error'] ?? 'Error al guardar usuario');
  }

  Future<void> guardarAlimentosIniciales(int usuarioId) async {
    for (final alimento in initialStock) {
      final response = await http.post(
        Uri.parse(
          'https://yost.es/SM-IT/2025-26/1B/website/mvp/insertar_despensa.php',
        ),
        body: {
          'usuario_id': usuarioId.toString(),
          'codigo': '',
          'nombre': alimento['nombre'].toString(),
          'marca': alimento['marca'].toString(),
          'ingredientes': '',
          'calorias': '0',
          'cantidad': alimento['cantidad'].toString(),
          'ultima_accion': '1',
          'favorito': '0',
        },
      );

      final data = jsonDecode(response.body);

      if (data['ok'] != true) {
        throw Exception(
          'Error al guardar "${alimento['nombre']}": ${data['error'] ?? 'desconocido'}',
        );
      }
    }
  }

  Future<void> finalizarOnboarding() async {
    setState(() {
      cargando = true;
    });

    try {
      final usuarioId = await guardarUsuarioYObtenerId();

      if (usuarioId == null) {
        throw Exception('No se pudo obtener el usuario_id');
      }

      if (initialStock.isNotEmpty) {
        await guardarAlimentosIniciales(usuarioId);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completado', true);
      await prefs.setInt('usuario_id', usuarioId);
      await prefs.setString('numero_pack', widget.numeroPack);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF527d5a);
    const beige = Color(0xFFd2b08b);
    const crema = Color(0xFFe9ddd4);
    const mostaza = Color(0xFFf1b810);
    const marron = Color(0xFF9d5d31);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8F6F2),
      appBar: AppBar(
        title: const Text(
          'Tu despensa',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: verde,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: verde),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Stack(
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
                  const Icon(
                    Icons.kitchen_rounded,
                    size: 42,
                    color: verde,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                '¿Qué tienes en casa?',
                style: TextStyle(
                  fontFamily: 'MoreSugar',
                  fontSize: 24,
                  color: verde,
                ),
              ),

              const SizedBox(height: 12),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Añade algunos alimentos que ya tengas para empezar con tu despensa personalizada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Color(0xFF6A6A6A),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: crema,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        hintText: 'Ej. leche, arroz, pasta...',
                        filled: true,
                        fillColor: crema.withOpacity(0.55),
                        prefixIcon: const Icon(
                          Icons.add_shopping_cart_rounded,
                          color: verde,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: verde,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: marcaController,
                      decoration: InputDecoration(
                        hintText: 'Marca (opcional)',
                        filled: true,
                        fillColor: crema.withOpacity(0.55),
                        prefixIcon: const Icon(
                          Icons.sell_rounded,
                          color: verde,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: verde,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cantidadController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Cantidad',
                              filled: true,
                              fillColor: crema.withOpacity(0.55),
                              prefixIcon: const Icon(
                                Icons.numbers_rounded,
                                color: verde,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: verde,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: verde,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: anadirAlimento,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      height: 190,
                      child: initialStock.isEmpty
                          ? const Center(
                              child: Text(
                                'Aún no has añadido alimentos',
                                style: TextStyle(
                                  color: Color(0xFF8A8A8A),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: initialStock.length,
                              itemBuilder: (context, index) {
                                final item = initialStock[index];
                                final marca = item['marca'].toString();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: crema.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          marca.isEmpty
                                              ? '${item['nombre']} x${item['cantidad']}'
                                              : '${item['nombre']} · $marca x${item['cantidad']}',
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            initialStock.removeAt(index);
                                          });
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          size: 18,
                                          color: marron,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: mostaza.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: marron,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'También podrás añadir productos más adelante usando el escáner integrado. Si falta información nutricional, intentaremos completarla automáticamente.',
                              style: TextStyle(
                                fontSize: 13,
                                color: marron,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: cargando
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        text: 'Finalizar',
                        onPressed: finalizarOnboarding,
                      ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}