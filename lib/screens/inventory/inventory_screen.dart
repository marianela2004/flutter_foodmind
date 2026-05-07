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
  late Future<List> _futureDespensa;
  String? nombreUsuario;

  static const Color verde = Color(0xFF527d5a);
  static const Color crema = Color(0xFFe9ddd4);
  static const Color mostaza = Color(0xFFf1b810);
  static const Color marron = Color(0xFF9d5d31);
  static const Color fondo = Color(0xFFF8F6F2);

  @override
void initState() {
  super.initState();
  _futureDespensa = obtenerDespensa();
  obtenerNombreUsuario();
  _actualizarCaducidadEnSegundoPlano();
}

Future<void> obtenerNombreUsuario() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');

    if (usuarioId == null) return;

    final response = await http.post(
      Uri.parse(
        'https://yost.es/SM-IT/2025-26/1B/website/mvp/obtener_usuario.php',
      ),
      body: {
        'usuario_id': usuarioId.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['ok'] == true) {
        final nombre = (data['nombre'] ?? '').toString().trim();

        if (!mounted) return;

        setState(() {
          nombreUsuario = nombre.isEmpty ? null : nombre;
        });
      }
    }
  } catch (_) {}
}

  Future<void> _actualizarCaducidadEnSegundoPlano() async {
    try {
      await actualizarCaducidadTodos();

      if (!mounted) return;

      setState(() {
        _futureDespensa = obtenerDespensa();
      });
    } catch (_) {
      // No mostramos error para no bloquear la pantalla.
    }
  }

  Future<List> cargarInventarioActualizado() async {
    await actualizarCaducidadTodos();
    return await obtenerDespensa();
  }

  Future<void> cambiarEstadoCaducidadManual(String id, String estado) async {
  final prefs = await SharedPreferences.getInstance();
  final usuarioId = prefs.getInt('usuario_id');

  if (usuarioId == null) return;

  final response = await http.post(
    Uri.parse(
      'https://yost.es/SM-IT/2025-26/1B/website/mvp/cambiar_estado_caducidad.php',
    ),
    body: {
      'id': id,
      'usuario_id': usuarioId.toString(),
      'estado_caducidad': estado,
    },
  );

  final data = jsonDecode(response.body);

  if (data['ok'] == true) {
    setState(() {
      _futureDespensa = obtenerDespensa();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Estado de caducidad actualizado')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['error'] ?? 'Error al actualizar estado')),
    );
  }
}

  Future<void> actualizarCaducidadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');

    if (usuarioId == null) {
      throw Exception("No se encontró el usuario actual");
    }

    final response = await http.post(
      Uri.parse(
        'https://yost.es/SM-IT/2025-26/1B/website/mvp/actualizar_caducidad_todos.php',
      ),
      body: {
        'usuario_id': usuarioId.toString(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception("No se pudo actualizar la caducidad");
    }

    final data = jsonDecode(response.body);

    if (data is! Map || data['ok'] != true) {
      throw Exception(data['error'] ?? "Error al recalcular la caducidad");
    }
  }

  Future<List> obtenerDespensa() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');

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
        return List.from(data['productos']);
      }

      throw Exception("Formato de respuesta no válido");
    } else {
      throw Exception("Error al cargar datos");
    }
  }

  Future<void> recargarInventario() async {
    setState(() {
      _futureDespensa = obtenerDespensa();
    });

    _actualizarCaducidadEnSegundoPlano();

    await _futureDespensa;
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
      Uri.parse(
        'https://yost.es/SM-IT/2025-26/1B/website/mvp/borrar_despensa.php',
      ),
      body: {
        "id": id,
        "usuario_id": usuarioId.toString(),
      },
    );

    final data = jsonDecode(response.body);

    if (data["ok"] == true) {
      setState(() {
        _futureDespensa = obtenerDespensa();
      });

      _actualizarCaducidadEnSegundoPlano();

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
      Uri.parse(
        'https://yost.es/SM-IT/2025-26/1B/website/mvp/favorito_despensa.php',
      ),
      body: {
        "id": id,
        "favorito": favorito.toString(),
        "usuario_id": usuarioId.toString(),
      },
    );

    final data = jsonDecode(response.body);

    if (data["ok"] == true) {
      setState(() {
        _futureDespensa = obtenerDespensa();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar favorito")),
      );
    }
  }

  Future<void> editarProducto({
    required String id,
    required String nombre,
    required String marca,
    required String cantidad,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id');

    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se encontró el usuario actual")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse(
        'https://yost.es/SM-IT/2025-26/1B/website/mvp/editar_despensa.php',
      ),
      body: {
        'id': id,
        'usuario_id': usuarioId.toString(),
        'nombre': nombre,
        'marca': marca,
        'cantidad': cantidad,
      },
    );

    final data = jsonDecode(response.body);

    if (data['ok'] == true) {
      setState(() {
        _futureDespensa = obtenerDespensa();
      });

      _actualizarCaducidadEnSegundoPlano();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Producto actualizado")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['error'] ?? 'Error al editar producto')),
      );
    }
  }

  void mostrarEditarProducto(Map item) {
    final nombreController =
        TextEditingController(text: (item['nombre'] ?? '').toString());
    final marcaController =
        TextEditingController(text: (item['marca'] ?? '').toString());
    final cantidadController =
        TextEditingController(text: (item['cantidad'] ?? '1').toString());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Editar producto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: verde,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    filled: true,
                    fillColor: crema.withOpacity(0.55),
                    prefixIcon: const Icon(
                      Icons.shopping_basket_rounded,
                      color: verde,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: marcaController,
                  decoration: InputDecoration(
                    labelText: 'Marca',
                    filled: true,
                    fillColor: crema.withOpacity(0.55),
                    prefixIcon: const Icon(Icons.sell_rounded, color: verde),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    filled: true,
                    fillColor: crema.withOpacity(0.55),
                    prefixIcon: const Icon(Icons.numbers_rounded, color: verde),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: marron),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: verde,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final nombre = nombreController.text.trim();
                          final marca = marcaController.text.trim();
                          final cantidad = cantidadController.text.trim();

                          if (nombre.isEmpty) return;

                          await editarProducto(
                            id: item['id'].toString(),
                            nombre: nombre,
                            marca: marca,
                            cantidad: cantidad,
                          );

                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void confirmarBorrado(String id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
            child: const Text(
              "Borrar",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

Color obtenerColorCaducidad(String estado) {
  final estadoBase = estado.replaceAll('_manual', '');

  switch (estadoBase) {
    case 'rojo':
      return Colors.red;
    case 'amarillo':
      return Colors.orange;
    default:
      return Colors.green;
  }
}

String obtenerTextoCaducidad(String estado) {
  final estadoBase = estado.replaceAll('_manual', '');

  switch (estadoBase) {
    case 'rojo':
      return 'Revisar ya';

    case 'amarillo':
      return 'Consumir pronto';

    default:
      return 'Fresco';
  }
}

  String limpiarValor(dynamic value) {
    final texto = (value ?? '').toString();
    if (texto.isEmpty || texto == 'null') return '0';
    return texto;
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: crema, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: crema,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              Positioned(
                top: 5,
                right: 3,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: mostaza,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Icon(
                Icons.kitchen_rounded,
                color: verde,
                size: 30,
              ),
            ],
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu inventario',
                  style: TextStyle(
                    fontFamily: 'MoreSugar',
                    fontSize: 24,
                    color: verde,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Consulta tus productos y revisa su estado de frescura.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF6A6A6A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 40),
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: crema, width: 1.2),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 54,
                  color: verde,
                ),
                SizedBox(height: 16),
                Text(
                  'Tu inventario está vacío',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: verde,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Añade productos para empezar a organizar tu despensa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7A7A7A),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 40),
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: crema, width: 1.2),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 54,
                  color: marron,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No se pudo cargar el inventario',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: verde,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7A7A7A),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }

  void mostrarDetalleNutricional(Map item) {
    final nombre = (item['nombre'] ?? 'Sin nombre').toString();
    final marca = (item['marca'] ?? '').toString();
    final calorias = limpiarValor(item['calorias']);
    final proteinas = limpiarValor(item['proteinas']);
    final carbohidratos = limpiarValor(item['carbohidratos']);
    final grasas = limpiarValor(item['grasas']);
    final azucares = limpiarValor(item['azucares']);
    final sal = limpiarValor(item['sal']);
    final energiaKj = limpiarValor(item['energia_kj']);
    final fuenteNutricional =
        (item['fuente_nutricional'] ?? 'manual').toString();
    final ingredientes = (item['ingredientes'] ?? '').toString();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: verde,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  marca.isEmpty ? 'Sin marca' : marca,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6A6A6A),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Información nutricional por 100 g',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: verde,
                  ),
                ),
                const SizedBox(height: 12),
                _NutritionRow(label: 'Calorías', value: '$calorias kcal'),
                _NutritionRow(label: 'Proteínas', value: '$proteinas g'),
                _NutritionRow(
                  label: 'Carbohidratos',
                  value: '$carbohidratos g',
                ),
                _NutritionRow(label: 'Grasas', value: '$grasas g'),
                _NutritionRow(label: 'Azúcares', value: '$azucares g'),
                _NutritionRow(label: 'Sal', value: '$sal g'),
                _NutritionRow(label: 'Energía', value: '$energiaKj kJ'),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: mostaza.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: marron),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fuenteNutricional.contains('openai')
                              ? 'Algunos valores pueden ser estimados automáticamente.'
                              : 'Fuente nutricional: $fuenteNutricional',
                          style: const TextStyle(
                            fontSize: 13,
                            color: marron,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (ingredientes.isNotEmpty && ingredientes != 'null') ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Ingredientes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: verde,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ingredientes,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: Color(0xFF6A6A6A),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(color: verde),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map item) {
    final esFavorito = item['favorito'].toString() == '1';
    final estadoCaducidad = item['estado_caducidad']?.toString() ?? 'verde';
    final colorCaducidad = obtenerColorCaducidad(estadoCaducidad);
    final textoCaducidad = obtenerTextoCaducidad(estadoCaducidad);

    final marca = (item['marca'] ?? '').toString();
    final cantidad = (item['cantidad'] ?? '').toString();
    final calorias = limpiarValor(item['calorias']);
    final motivoIA = (item['motivo_ia'] ?? '').toString();
    final fechaCaducidad = (item['fecha_estimada_caducidad'] ?? '').toString();
    final diasEstimados = (item['dias_estimados'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: crema, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => mostrarDetalleNutricional(item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: crema.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shopping_basket_rounded,
                  color: verde,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: verde,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      marca.isEmpty ? 'Marca: Sin marca' : 'Marca: $marca',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6A6A6A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cantidad: $cantidad',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6A6A6A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Calorías: $calorias kcal/100g',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6A6A6A),
                      ),
                    ),
                    if (fechaCaducidad.isNotEmpty &&
                        fechaCaducidad != 'null') ...[
                      const SizedBox(height: 2),
                      Text(
                        'Caducidad estimada: $fechaCaducidad',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6A6A6A),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        final tieneDias = diasEstimados.isNotEmpty &&
                            diasEstimados != 'null';
                        final tieneMotivo =
                            motivoIA.isNotEmpty && motivoIA != 'null';

                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: colorCaducidad,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        textoCaducidad,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: colorCaducidad,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    tieneDias
                                        ? 'Duración estimada: $diasEstimados días'
                                        : 'No hay una estimación de días disponible.',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF4F4F4F),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    tieneMotivo
                                        ? motivoIA
                                        : 'No hay una explicación disponible todavía.',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6A6A6A),
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
const Text(
  'Corregir estado manualmente',
  style: TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: verde,
  ),
),

const SizedBox(height: 12),

Wrap(
  spacing: 10,
  runSpacing: 10,
  children: [

    SizedBox(
      width: 115,
      height: 44,
      child: ElevatedButton(
        onPressed: () async {
          Navigator.pop(context);

          await cambiarEstadoCaducidadManual(
            item['id'].toString(),
            'verde_manual',
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Fresco',
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.fade,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),

    SizedBox(
      width: 115,
      height: 44,
      child: ElevatedButton(
        onPressed: () async {
          Navigator.pop(context);

          await cambiarEstadoCaducidadManual(
            item['id'].toString(),
            'amarillo_manual',
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Pronto',
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.fade,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),

    SizedBox(
      width: 115,
      height: 44,
      child: ElevatedButton(
        onPressed: () async {
          Navigator.pop(context);

          await cambiarEstadoCaducidadManual(
            item['id'].toString(),
            'rojo_manual',
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Revisar',
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.fade,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),

  ],
),              const SizedBox(height: 18),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        'Cerrar',
                                        style: TextStyle(color: verde),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorCaducidad.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 9,
                              height: 9,
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
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      esFavorito ? Icons.favorite : Icons.favorite_border,
                      color: esFavorito ? Colors.red : marron.withOpacity(0.7),
                    ),
                    onPressed: () {
                      cambiarFavorito(
                        item['id'].toString(),
                        esFavorito ? 0 : 1,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: verde,
                    ),
                    onPressed: () {
                      mostrarEditarProducto(item);
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      confirmarBorrado(
                        item['id'].toString(),
                        item['nombre'] ?? 'producto',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: fondo,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
  nombreUsuario != null && nombreUsuario!.isNotEmpty
      ? "Inventario de $nombreUsuario"
      : "Inventario",
  style: const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: verde,
  ),
),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Recargar',
              onPressed: recargarInventario,
              icon: const Icon(Icons.refresh_rounded, color: verde),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: verde,
          foregroundColor: Colors.white,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddProductScreen(),
              ),
            );

            setState(() {
              _futureDespensa = obtenerDespensa();
            });

            _actualizarCaducidadEnSegundoPlano();
          },
          child: const Icon(Icons.add),
        ),
        body: RefreshIndicator(
          color: verde,
          onRefresh: recargarInventario,
          child: FutureBuilder<List>(
            future: _futureDespensa,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 140),
                    Center(child: CircularProgressIndicator(color: verde)),
                  ],
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error!);
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 110),
                itemCount: items.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildHeader();
                  final item = items[index - 1];
                  return _buildProductCard(item);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final String value;

  const _NutritionRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF527d5a);
    const crema = Color(0xFFe9ddd4);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: crema.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF6A6A6A),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: verde,
            ),
          ),
        ],
      ),
    );
  }
}