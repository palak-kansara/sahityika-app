import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  late Future<Profile> _future;

  @override
  void initState() {
    super.initState();
    _future = ProfileService.fetchProfile();
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Profile",
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 20),

            Expanded(
              child: FutureBuilder<Profile>(
                future: _future,
                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Failed to load profile"),
                    );
                  }

                  final profile = snapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      _infoCard(
                        context,
                        "Name",
                        profile.firstName.isEmpty
                            ? "No name added"
                            : profile.firstName,
                      ),

                      const SizedBox(height: 16),

                      _infoCard(
                        context,
                        "Household",
                        profile.householdName,
                      ),

                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}