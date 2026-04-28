import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/primary_button.dart';
import 'allergies_screen.dart';

class DietScreen extends StatefulWidget {
  final String numeroPack;
  final bool editingFromSettings;

  const DietScreen({
    super.key,
    required this.numeroPack,
    this.editingFromSettings = false,
  });

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  final TextEditingController _detailsController = TextEditingController();

  final List<String> dietOptions = const [
    'Omnívora',
    'Vegana',
    'Vegetariana',
    'Embarazo',
    'Lactancia',
    'Menopausia',
    'SOP',
    'Tiroides',
    'Hipertensión',
    'Persona mayor',
  ];

  final Set<String> selectedDiets = {};

  @override
  void initState() {
    super.initState();
    cargarDietaGuardada();
  }

  Future<void> cargarDietaGuardada() async {
    final prefs = await SharedPreferences.getInstance();

    final savedOptions = prefs.getString('dietas_usuario');
    final savedDetails = prefs.getString('detalle_dieta_usuario') ?? '';

    if (savedOptions != null) {
      selectedDiets.addAll(List<String>.from(jsonDecode(savedOptions)));
    }

    _detailsController.text = savedDetails;
    setState(() {});
  }

  Future<void> guardarDieta() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'dietas_usuario',
      jsonEncode(selectedDiets.toList()),
    );

    await prefs.setString(
      'detalle_dieta_usuario',
      _detailsController.text.trim(),
    );

    final dietaCompleta = {
      'opciones': selectedDiets.toList(),
      'detalle': _detailsController.text.trim(),
    };

    await prefs.setString('dieta_usuario', jsonEncode(dietaCompleta));
  }

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF527d5a);
    const crema = Color(0xFFe9ddd4);
    const beige = Color(0xFFd2b08b);
    const mostaza = Color(0xFFf1b810);
    const marron = Color(0xFF9d5d31);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8F6F2),
      appBar: AppBar(
        title: const Text(
          'Tu alimentación',
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
                  const Icon(Icons.eco_rounded, size: 42, color: verde),
                ],
              ),

              const SizedBox(height: 40),

              const Text(
                'Cuéntanos cómo comes',
                style: TextStyle(
                  fontFamily: 'MoreSugar',
                  fontSize: 26,
                  color: verde,
                ),
              ),

              const SizedBox(height: 12),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Selecciona las opciones que se ajusten a ti para adaptar mejor tu menú diario.',
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
                  border: Border.all(color: crema, width: 1.2),
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
                          Icons.restaurant_menu_rounded,
                          size: 18,
                          color: marron,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tipo de alimentación',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: verde,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: dietOptions.map((option) {
                        final selected = selectedDiets.contains(option);

                        return GestureDetector(
                          onTap: () {
  setState(() {
    if (selected) {
      selectedDiets.remove(option);
      return;
    }

    // Grupo alimentación: solo una opción
    if (['Omnívora', 'Vegana', 'Vegetariana'].contains(option)) {
      selectedDiets.remove('Omnívora');
      selectedDiets.remove('Vegana');
      selectedDiets.remove('Vegetariana');
    }

    // Grupo etapa vital: solo una opción
    if (['Embarazo', 'Lactancia', 'Menopausia', 'Persona mayor']
        .contains(option)) {
      selectedDiets.remove('Embarazo');
      selectedDiets.remove('Lactancia');
      selectedDiets.remove('Menopausia');
      selectedDiets.remove('Persona mayor');
    }

    selectedDiets.add(option);
  });
},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? verde
                                  : crema.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected ? verde : crema,
                              ),
                            ),
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : verde,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 22),

                    const Row(
                      children: [
                        Icon(Icons.edit_note_rounded, size: 18, color: marron),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Detalles personalizados',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: verde,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: _detailsController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            'Ej. mínimo 90g de proteína al día, 1800 kcal, dieta ayurveda, baja en sal...',
                        hintStyle: const TextStyle(color: Color(0xFF8E857D)),
                        filled: true,
                        fillColor: crema.withOpacity(0.55),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              const BorderSide(color: verde, width: 1.5),
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
                          Icon(Icons.info_outline, size: 18, color: marron),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Esta información se usará para personalizar tus experiencia en la aplicación.',
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
                      child: PrimaryButton(
                        text: 'Continuar',
                        onPressed: () async {
                          if (selectedDiets.isEmpty &&
                              _detailsController.text.trim().isEmpty) {
                            return;
                          }

                          await guardarDieta();

                          final dietaParaSiguientePantalla = jsonEncode({
                            'opciones': selectedDiets.toList(),
                            'detalle': _detailsController.text.trim(),
                          });

                          if (widget.editingFromSettings) {
                            Navigator.pop(context);
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AllergiesScreen(
                                numeroPack: widget.numeroPack,
                                diet: dietaParaSiguientePantalla,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Podrás modificar esta información más adelante.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8A8A8A),
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