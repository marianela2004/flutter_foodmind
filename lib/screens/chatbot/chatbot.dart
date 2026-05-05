import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Chatbot extends StatefulWidget {
  const Chatbot({super.key});

  @override
  State<Chatbot> createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot>
    with SingleTickerProviderStateMixin {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> messages = [];
  bool loading = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  static const Color verde = Color(0xFF527d5a);
  static const Color crema = Color(0xFFe9ddd4);

  @override
  void initState() {
    super.initState();

    /// ✨ Animación tipo "nube"
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack);

    _animationController.forward();

    messages.add({
      "role": "bot",
      "text":
          "¡Hola! Me presento, soy CocinIA, tu chatbot de recetas de confianza.\n\nTe crearé recetas rápidas y nutritivas con lo que tienes en la nevera.\n\nDime que quieres comer y yo te ayudo☺️"
    });

    scrollToBottom();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 🔽 SCROLL AUTOMÁTICO
  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 🔥 INVENTARIO
  Future<List<String>> obtenerIngredientes() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');

    final response = await http.post(
      Uri.parse(
          'https://yost.es/SM-IT/2025-26/1B/website/mvp/despensa.php'),
      body: {'usuario_id': usuarioId.toString()},
    );

    final data = jsonDecode(response.body);

    List items = data is List ? data : data['productos'] ?? [];

    return items.map((e) => e['nombre'].toString()).toList();
  }

  /// 🔥 IA
  Future<String> generarReceta(String mensaje) async {
    final ingredientes = await obtenerIngredientes();
    final inventarioTexto = ingredientes.join(", ");

    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');

    final response = await http.post(
      Uri.parse(
          "https://yost.es/SM-IT/2025-26/1B/website/mvp/cocinia.php"),
      body: {
        "usuario_id": usuarioId.toString(),
        "mensaje": mensaje,
        "inventario": inventarioTexto,
      },
    );

    final data = jsonDecode(response.body);

    return data["respuesta"] ?? "No pude generar receta 😢";
  }

  /// 💬 ENVIAR
  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    final texto = controller.text;

    setState(() {
      messages.add({"role": "user", "text": texto});
      loading = true;
    });

    controller.clear();
    scrollToBottom();

    final respuesta = await generarReceta(texto);

    setState(() {
      messages.add({"role": "bot", "text": respuesta});
      loading = false;
    });

    scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.3),

      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            decoration: BoxDecoration(
              color: crema,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                )
              ],
            ),
            child: Column(
              children: [
                /// 🔝 HEADER
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: verde,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage:
                            AssetImage('assets/images/cocinia.png'),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "CocinIA",
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),

                /// 💬 CHAT
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= messages.length) {
                        scrollToBottom();

                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const TypingDots(),
                          ),
                        );
                      }

                      final msg = messages[index];
                      final isUser = msg["role"] == "user";

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? verde : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            msg["text"]!,
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// ✏️ INPUT
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: "Escribe tu receta...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: sendMessage,
                        icon: const Icon(Icons.send, color: verde),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🔥 WIDGET PUNTITOS ANIMADOS
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget dot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        double value = (_controller.value + index * 0.2) % 1;
        double opacity = (value < 0.5) ? value * 2 : (1 - value) * 2;

        return Opacity(
          opacity: opacity,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: CircleAvatar(
              radius: 3,
              backgroundColor: Colors.grey,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [dot(0), dot(1), dot(2)],
    );
  }
}