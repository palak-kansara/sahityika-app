import 'dart:convert';

import '../constants/api_constants.dart';
import '../models/profile.dart';
import 'api_client.dart';

class ProfileService {

  static Future<Profile> fetchProfile() async {

    final response = await ApiClient.get(ApiConstants.profile);

    if (response.statusCode != 200) {
      throw Exception('Failed to load profile');
    }

    final decoded = jsonDecode(response.body);
    print(decoded);

    return Profile.fromJson(decoded);
  }
}