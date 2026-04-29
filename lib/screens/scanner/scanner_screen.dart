import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  final MobileScannerController scannerController = MobileScannerController(
    autoStart: true,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  final TextEditingController codigoController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController marcaController = TextEditingController();
  final TextEditingController ingredientesController = TextEditingController();
  final TextEditingController caloriasController = TextEditingController();
  final TextEditingController cantidadController =
      TextEditingController(text: '1');

  bool cargandoProducto = false;
  bool guardando = false;
  bool mostrandoModal = false;
  bool scannerActivo = true;

  static const Color verde = Color(0xFF527d5a);
  static const Color beige = Color(0xFFd2b08b);
  static const Color crema = Color(0xFFe9ddd4);
  static const Color mostaza = Color(0xFFf1b810);
  static const Color marron = Color(0xFF9d5d31);
  static const Color fondo = Color(0xFFF8F6F2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    scannerController.dispose();
    codigoController.dispose();
    nombreController.dispose();
    marcaController.dispose();
    ingredientesController.dispose();
    caloriasController.dispose();
    cantidadController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && !mostrandoModal) {
      scannerController.start();
      scannerActivo = true;
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      scannerController.stop();
      scannerActivo = false;
    }
  }

  void limpiarCampos() {
    codigoController.clear();
    nombreController.clear();
    marcaController.clear();
    ingredientesController.clear();
    caloriasController.clear();
    cantidadController.text = '1';
  }

  Future<void> buscarProductoPorCodigo(String barcode) async {
    if (!mounted) return;

    setState(() {
      cargandoProducto = true;
    });

    codigoController.text = barcode;

    try {
      final response = await http.get(
        Uri.parse('https://world.openfoodfacts.org/api/v2/product/$barcode'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final product = data['product'];

        if (product != null) {
          final nutriments = product['nutriments'] ?? {};

          nombreController.text = product['product_name'] ?? '';
          marcaController.text = product['brands'] ?? '';
          ingredientesController.text = product['ingredients_text'] ?? '';
          caloriasController.text =
              nutriments['energy-kcal_100g']?.toString() ?? '0';

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
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');

      if (usuarioId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró el usuario actual'),
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse(
          'https://yost.es/SM-IT/2025-26/1B/website/mvp/insertar_despensa.php',
        ),
        body: {
          'usuario_id': usuarioId.toString(),
          'codigo': codigoController.text,
          'nombre': nombreController.text.trim(),
          'marca': marcaController.text.trim(),
          'ingredientes': ingredientesController.text,
          'calorias': caloriasController.text.trim().isEmpty
    ? '0'
    : caloriasController.text.trim(),
'proteinas': '0',
'carbohidratos': '0',
'grasas': '0',
'azucares': '0',
'sal': '0',
'energia_kj': '0',
'cantidad': cantidadController.text.trim(),
          'ultima_accion': '1',
          'favorito': '0',
        },
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (data['ok'] == true) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto guardado correctamente'),
          ),
        );
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

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    bool readOnly = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: verde,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF8E857D),
      ),
      filled: true,
      fillColor: readOnly ? crema.withOpacity(0.35) : crema.withOpacity(0.55),
      prefixIcon: Icon(icon, color: verde),
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
    );
  }

  Future<void> reanudarScanner() async {
    if (!mounted) return;
    limpiarCampos();
    mostrandoModal = false;

    if (!scannerActivo) {
      try {
        await scannerController.start();
        scannerActivo = true;
      } catch (_) {}
    }
  }

  Future<void> mostrarFichaProducto() async {
    if (!mounted) return;

    final bool? guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: fondo,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                color: crema,
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 0,
                              child: Container(
                                width: 16,
                                height: 16,
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
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: beige,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.inventory_2_rounded,
                              size: 38,
                              color: verde,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Producto detectado',
                          style: TextStyle(
                            fontFamily: 'MoreSugar',
                            fontSize: 24,
                            color: verde,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Revisa los datos antes de guardar el producto en tu inventario.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Color(0xFF6A6A6A),
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextField(
                          controller: codigoController,
                          readOnly: true,
                          decoration: inputDecoration(
                            label: 'Código de barras',
                            icon: Icons.qr_code_2_rounded,
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: nombreController,
                          decoration: inputDecoration(
                            label: 'Nombre',
                            icon: Icons.shopping_bag_outlined,
                            hint: 'Nombre del producto',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: marcaController,
                          decoration: inputDecoration(
                            label: 'Marca',
                            icon: Icons.storefront_outlined,
                            hint: 'Marca',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: cantidadController,
                          keyboardType: TextInputType.number,
                          decoration: inputDecoration(
                            label: 'Cantidad',
                            icon: Icons.numbers,
                            hint: 'Ej. 1',
                          ),
                        ),
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
                                  'Solo se muestran los datos esenciales para revisar rápido el producto.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: marron,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: guardando
                                ? null
                                : () async {
                                    setModalState(() {});
                                    await guardarProducto();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: verde,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: guardando
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Guardar producto',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: verde,
                              side: BorderSide(
                                color: verde.withOpacity(0.25),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Escanear otro',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await reanudarScanner();

    if (guardado == true) {
      limpiarCampos();
    }
  }

  Future<void> onDetect(BarcodeCapture capture) async {
    if (mostrandoModal || cargandoProducto || guardando) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    mostrandoModal = true;

    try {
      await scannerController.stop();
      scannerActivo = false;

      await buscarProductoPorCodigo(code);
      await mostrarFichaProducto();
    } catch (e) {
      mostrandoModal = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar el escaneo: $e')),
      );
      await reanudarScanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: scannerController,
              onDetect: onDetect,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                    Colors.black.withOpacity(0.45),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.flash_on, color: Colors.white),
                          onPressed: () => scannerController.toggleTorch(),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.cameraswitch, color: Colors.white),
                          onPressed: () => scannerController.switchCamera(),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.22),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Escanea un producto',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'MoreSugar',
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Apunta con la cámara al código de barras y revisa los datos antes de guardar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white,
                        width: 2.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 26,
                          right: 26,
                          child: Container(
                            height: 4,
                            color: mostaza,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 26,
                          right: 26,
                          child: Container(
                            height: 4,
                            color: mostaza,
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 26,
                          bottom: 26,
                          child: Container(
                            width: 4,
                            color: mostaza,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 26,
                          bottom: 26,
                          child: Container(
                            width: 4,
                            color: mostaza,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (cargandoProducto)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Buscando producto...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Text(
                      'Coloca el código dentro del marco',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}