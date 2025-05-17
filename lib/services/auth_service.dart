import 'package:flutter/foundation.dart';
import 'package:campus_care/config/supabase_config.dart';
import 'package:campus_care/models/user_model.dart';

class AuthService {
  Future<UserModel?> getCurrentUser() async {
    try {
      final supabase = SupabaseConfig.supabaseClient;
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final response = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  Future<UserModel?> signUp(String email, String password) async {
    try {
      final supabase = SupabaseConfig.supabaseClient;
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Create user record in users table
        await supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'role': 'student', // Default role
        });

        // Fetch the created user
        final userResponse = await supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        return UserModel.fromJson(userResponse);
      }
      return null;
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final supabase = SupabaseConfig.supabaseClient;
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userResponse = await supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        return UserModel.fromJson(userResponse);
      }
      return null;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    final supabase = SupabaseConfig.supabaseClient;
    await supabase.auth.signOut();
  }
}
