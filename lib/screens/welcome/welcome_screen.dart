import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';
import '../onboarding/diet_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // ⭐ TU IMAGEN AQUÍ ⭐
            SizedBox(
              height: 250,
              child: Image.asset(
                'assets/images/start_image.png',
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "FOODMIND",
               style: TextStyle(
               fontFamily: 'MoreSugar',
               fontSize: 40,
               color: Color(0xFF537e5e),
              ),
            ),

            const SizedBox(height: 40),

            PrimaryButton(
              text: "Empezar",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DietScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}