import 'package:flutter/material.dart';
import 'login_screen.dart';

class LoginLandingScreen extends StatelessWidget {
  const LoginLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sahityika',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),

            Text(
              'વાંચનથી વિચાર સુધી',
              style: const TextStyle(
                fontFamily: 'NotoSerifGujarati',
                fontSize: 18,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
