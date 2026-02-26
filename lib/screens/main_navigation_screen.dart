import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'favourites_screen.dart';
import 'isbn_scanner_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
    int _selectedIndex = 0;

    late final List<Widget> _screens = [
        const HomeScreen(),               // index 0 → Home
        const FavouritesScreen(),    // ⭐ Favourites
        const SizedBox.shrink(),           // index 2 (handled by + button)
        const Center(child: Text('Reading Progress')), // index 3
        const Center(child: Text('Profile')), // index 4
    ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],// placeholder for now

      // Center + button (Add Book)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ISBNScannerScreen(),
            ),
          );
        },
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        height: 64,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: 'Favourites',
          ),
          NavigationDestination(
            icon: SizedBox.shrink(), // placeholder for +
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Reading',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  /// Temporary placeholder body
  Widget _buildBody() {
    return const Center(
      child: Text(
        'Main Screen',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
