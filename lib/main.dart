// import 'package:flutter/material.dart';
// import 'screens/login_screen.dart';
// import 'screens/isbn_scanner_screen.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Book Catalog',
//       initialRoute: '/',
//       routes: {
//         '/': (context) => const LoginScreen(),
//         '/home': (context) => const HomeScreen(),
//         '/isbn-scan': (context) => const ISBNScannerScreen(),
//       },
//     );
//   }
// }

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Book Catalog")),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () {
//             Navigator.pushNamed(context, '/isbn-scan');
//           },
//           child: const Text("Scan ISBN"),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'screens/auth_check.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() {
  runApp(const SahityikaApp());
}

class SahityikaApp extends StatelessWidget {
  const SahityikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      // home: const AuthCheck(),
      home: const MainNavigationScreen(),
    );
  }
}

