import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email, password and display name
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName, // custom user metadata
      },
    );

    return response;
  }

  // Optional: Update display name after registration (if needed)
  Future<void> updateDisplayName(String displayName) async {
    await _supabase.auth.updateUser(
      UserAttributes(data: {
        'display_name': displayName,
      }),
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get current user email
  String? getCurrentUserEmail() {
    final user = _supabase.auth.currentUser;
    return user?.email;
  }

  // Get display name
  String? getCurrentDisplayName() {
    final user = _supabase.auth.currentUser;
    return user?.userMetadata?['display_name'];
  }
}
