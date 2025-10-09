import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for user profile data.
class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
  });
}

/// Riverpod AsyncNotifier to manage user profile state.
class ProfileController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    return await _fetchUserProfile();
  }

  Future<UserProfile?> _fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      final data = doc.data();
      final name = data?['displayName'] ?? user.displayName ?? 'User';
      final phone = data?['phone'] ?? 'N/A';
      final email = user.email ?? 'No email available';
      final photoUrl = data?['photoUrl'] ?? user.photoURL;

      return UserProfile(
        name: name,
        email: email,
        phone: phone,
        photoUrl: photoUrl,
      );
    } catch (e) {
      print('\x1B[34mProfile load error: $e\x1B[0m');
      return null;
    }
  }

  /// Refresh Firestore + Auth data after edits.
  Future<void> refreshProfile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => await _fetchUserProfile());
  }
}

/// Global provider to be used across app.
final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile?>(() {
  return ProfileController();
});
