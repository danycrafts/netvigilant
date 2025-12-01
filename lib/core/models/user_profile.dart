import 'dart:io';

class UserProfile {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phone;
  final File? profileImage;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phone,
    this.profileImage,
  });

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    File? profileImage,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
    };
  }
}