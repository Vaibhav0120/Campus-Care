import 'package:flutter/material.dart';
import 'package:campus_care/models/user_model.dart';
import 'package:campus_care/config/supabase_config.dart';
// ignore: unused_import
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isStaff => _user?.isStaff ?? false;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check and restore session on app start
  Future<bool> checkAndRestoreSession() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final supabase = SupabaseConfig.supabaseClient;
      
      // Get current session
      final session = supabase.auth.currentSession;
      
      if (session != null) {
        // Session exists, fetch user data
        final userId = session.user.id;
        final userData = await supabase
            .from('users')
            .select()
            .eq('id', userId)
            .single();
        
        _user = UserModel.fromJson(userData);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Sign in user with email and password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final supabase = SupabaseConfig.supabaseClient;
      
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        final userId = response.user!.id;
        final userData = await supabase
            .from('users')
            .select()
            .eq('id', userId)
            .single();
        
        _user = UserModel.fromJson(userData);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _error = 'Invalid email or password';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final supabase = SupabaseConfig.supabaseClient;
      
      // Updated for Supabase Flutter 2.x
      final success = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin,
      );

      // signInWithOAuth returns a bool indicating if the redirect was initiated
      if (success) {
        // We'll handle the actual user data in the checkAndRestoreSession method
        // after the OAuth flow completes
        return true;
      }

      _error = 'Failed to initiate Google sign in';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign up user with email and password
  Future<bool> signUp(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final supabase = SupabaseConfig.supabaseClient;
      
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        final userId = response.user!.id;
        
        // Create user profile with student role
        await supabase.from('users').insert({
          'id': userId,
          'email': email,
          'role': 'student',
          'created_at': DateTime.now().toIso8601String(),
        });
        
        final userData = await supabase
            .from('users')
            .select()
            .eq('id', userId)
            .single();
        
        _user = UserModel.fromJson(userData);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _error = 'Failed to create account';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out user
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      final supabase = SupabaseConfig.supabaseClient;
      await supabase.auth.signOut();
      _user = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}