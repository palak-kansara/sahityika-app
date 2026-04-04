import 'package:flutter/material.dart';
import '../widgets/book_list_view.dart';
import '../enums/book_list_mode.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              'Favourites',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 20),

            Expanded(
              child: BookListView(
                mode: BookListMode.favourites,
              ),
            ),

          ],
        ),
      ),
    );
  }
}