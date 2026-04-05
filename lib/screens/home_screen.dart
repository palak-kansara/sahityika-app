import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'login_landing.dart';
import '../widgets/book_list_view.dart';
import '../enums/book_list_mode.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await StorageService.getUserName();
    setState(() => _userName = name ?? '');
  }

  Future<void> _logout() async {
    await StorageService.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginLandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Text(
                    'Welcome $_userName',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),

                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    tooltip: 'Logout',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// Reusable Book List
              const Expanded(
                child: BookListView(
                  mode: BookListMode.listing,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}