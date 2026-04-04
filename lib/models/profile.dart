class Profile {
  final int id;
  final String firstName;
  final String householdName;

  Profile({
    required this.id,
    required this.firstName,
    required this.householdName,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      firstName: json['full_name']?? '',
      householdName: json['household']['name'] ?? '',
    );
  }
}