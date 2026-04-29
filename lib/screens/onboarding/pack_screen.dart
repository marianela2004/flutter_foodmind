import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/primary_button.dart';
import '../home/home_screen.dart';
import 'diet_screen.dart';

class PackScreen extends StatefulWidget {
  final bool editingFromSettings;

  const PackScreen({super.key, this.editingFromSettings = false});

  @override
  State<PackScreen> createState() => _PackScreenState();
}

class _PackScreenState extends State<PackScreen> {
  final TextEditingController numeroPackController = TextEditingController();

  bool cargando = false;

  @override
  void dispose() {
    numeroPackController.dispose();
    super.dispose();
  }

Future<void> abrirWebPlanes() async {
  final url = Uri.parse('https://yost.es/SM-IT/2025-26/1B/website/wp/precios/');

  try {
    await launchUrl(
      url,
      mode: LaunchMode.platformDefault,
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo abrir la web: $e')),
    );
  }
}
  Future<void> continuar() async {
    final numeroPack = numeroPackController.text.trim();

    if (numeroPack.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce el número de pack')),
      );
      return;
    }

    if (widget.editingFromSettings) {
      final response = await http.post(
        Uri.parse('https://yost.es/SM-IT/2025-26/1B/website/mvp/validar_pack.php'),
        body: {'numero_pack': numeroPack},
      );

      final body = response.body.trim();

      if (body.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El servidor devolvió una respuesta vacía')),
        );
        return;
      }

      dynamic data;
      try {
        data = jsonDecode(body);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Respuesta no válida del servidor')),
        );
        return;
      }

      if (response.statusCode == 200 && data['ok'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('numero_pack', numeroPack);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Número de pack actualizado')),
        );

        Navigator.pop(context);
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Número de pack no válido')),
        );
        return;
      }
    }

    setState(() => cargando = true);

    try {
      final response = await http.post(
        Uri.parse(
          'https://yost.es/SM-IT/2025-26/1B/website/mvp/validar_pack.php',
        ),
        body: {
          'numero_pack': numeroPack,
        },
      );

      if (!mounted) return;

      final body = response.body.trim();

      if (body.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El servidor devolvió una respuesta vacía'),
          ),
        );
        return;
      }

      dynamic data;
      try {
        data = jsonDecode(body);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Respuesta no válida del servidor'),
          ),
        );
        return;
      }

      if (response.statusCode == 200 && data['ok'] == true) {
        final bool usado = data['usado'] == true;

        if (!usado) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DietScreen(
                numeroPack: numeroPack,
              ),
            ),
          );
        } else {
          final usuarioId = data['usuario_id'];

          if (usuarioId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El pack ya está usado, pero no tiene usuario asociado'),
              ),
            );
            return;
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('usuario_id', int.parse(usuarioId.toString()));
          await prefs.setString('numero_pack', numeroPack);
          await prefs.setBool('onboarding_completado', true);

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['error'] ?? 'Número de pack no válido',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => cargando = false);
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
      backgroundColor: const Color(0xFFF8F6F2),
      appBar: AppBar(
        title: Text(
          widget.editingFromSettings ? 'Editar pack' : 'Tu dispositivo',
          style: const TextStyle(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
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
                      Icons.qr_code_2_rounded,
                      size: 44,
                      color: verde,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  widget.editingFromSettings
                      ? 'Editar número de pack'
                      : 'Conecta tu pack',
                  style: const TextStyle(
                    fontFamily: 'MoreSugar',
                    fontSize: 26,
                    color: verde,
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Introduce el número de tu pack para vincular tu despensa y empezar a personalizar la experiencia.',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.link_rounded,
                            size: 18,
                            color: marron,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Número de pack',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: verde,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: numeroPackController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Ej. 2604',
                          hintStyle: const TextStyle(
                            color: Color(0xFF8E857D),
                          ),
                          filled: true,
                          fillColor: crema.withOpacity(0.55),
                          prefixIcon: const Icon(
                            Icons.numbers,
                            color: verde,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
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
                                'Este número identifica tu pack y tu despensa personal.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: marron,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: cargando
                            ? const Center(child: CircularProgressIndicator())
                            : PrimaryButton(
                                text: widget.editingFromSettings
                                    ? 'Guardar cambios'
                                    : 'Continuar',
                                onPressed: continuar,
                              ),
                      ),

                      if (!widget.editingFromSettings) ...[
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            '¿Aún no tienes código?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: verde,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Para obtener tu código, consulta los planes en nuestra web.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Color(0xFF6A6A6A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: GestureDetector(
                            onTap: abrirWebPlanes,
                            child: const Text(
                              'Ver planes en la web',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: marron,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}