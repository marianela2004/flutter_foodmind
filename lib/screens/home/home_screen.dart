import 'package:flutter/material.dart';
import '../inventory/inventory_screen.dart';
import '../scanner/scanner_screen.dart';
import '../settings/settings_screen.dart';
import '../consumption/consumption_screen.dart';
import '../favorites/favorites_screen.dart';
import '../menu/menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  final screens = const [
    InventoryScreen(),
    MenuScreen(),
    ScannerScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: screens[index],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: index,
          selectedItemColor: const Color(0xFF537e5e),
          unselectedItemColor: Colors.black54,
          onTap: (i) => setState(() => index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.kitchen),
              label: "Inventario",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: "Menú",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: "Escanear",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: "Más",
            ),
          ],
        ),
      ),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF527d5a);
    const crema = Color(0xFFe9ddd4);
    const beige = Color(0xFFd2b08b);
    const mostaza = Color(0xFFf1b810);
    const marron = Color(0xFF9d5d31);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      appBar: AppBar(
        title: const Text(
          'Más',
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ICONO
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
                    Icons.more_horiz_rounded,
                    size: 42,
                    color: verde,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Más opciones',
                style: TextStyle(
                  fontFamily: 'MoreSugar',
                  fontSize: 24,
                  color: verde,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Gestiona tus preferencias y accede a funciones adicionales.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Color(0xFF6A6A6A),
                ),
              ),

              const SizedBox(height: 30),

              _MoreItem(
                icon: Icons.local_dining,
                title: "Seguimiento inteligente",
                subtitle: "Analiza tu consumo y hábitos",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConsumptionScreen()),
                  );
                },
              ),
              _MoreItem(
                icon: Icons.favorite,
                title: "Favoritos",
                subtitle: "Tus comidas guardadas",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                  );
                },
              ),
              _MoreItem(
                icon: Icons.settings,
                title: "Ajustes",
                subtitle: "Configura tu cuenta",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),

              const Spacer(),

              // AVISO LEGAL
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: mostaza.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: mostaza.withOpacity(0.25),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: marron),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'FoodMind ofrece recomendaciones orientativas y no sustituye el asesoramiento de un profesional sanitario. '
                        'La aplicación no se hace responsable del uso de la información proporcionada.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: marron,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const verde = Color(0xFF527d5a);
    const crema = Color(0xFFe9ddd4);
    const marron = Color(0xFF9d5d31);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: crema.withOpacity(0.65),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: verde),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: verde,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF6A6A6A),
          ),
        ),
        trailing:
            const Icon(Icons.chevron_right_rounded, color: marron),
        onTap: onTap,
      ),
    );
  }
}