import 'package:flutter/material.dart';
import 'package:campus_care/models/user_model.dart';
import 'package:campus_care/config/supabase_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
        
        try {
          final userData = await supabase
              .from('users')
              .select()
              .eq('id', userId)
              .single();
          
          _user = UserModel.fromJson(userData);
          _isLoading = false;
          notifyListeners();
          return true;
        } catch (e) {
          // If user doesn't exist in the users table yet, create them
          // This handles cases where a user signs in with OAuth but doesn't have a record
          if (e.toString().contains('multiple (or no) rows')) {
            await _createUserRecord(userId, session.user.email ?? '');
            return true;
          } else {
            rethrow;
          }
        }
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Create a user record if it doesn't exist (for OAuth users)
  Future<void> _createUserRecord(String userId, String email) async {
    try {
      final supabase = SupabaseConfig.supabaseClient;
      
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
    } catch (e) {
      _error = 'Failed to create user profile: $e';
      _isLoading = false;
      notifyListeners();
    }
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
        
        try {
          final userData = await supabase
              .from('users')
              .select()
              .eq('id', userId)
              .single();
          
          _user = UserModel.fromJson(userData);
          _isLoading = false;
          notifyListeners();
          return true;
        } catch (e) {
          // If user doesn't exist in the users table yet, create them
          if (e.toString().contains('multiple (or no) rows')) {
            await _createUserRecord(userId, email);
            return true;
          } else {
            rethrow;
          }
        }
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
      
      // Different redirect handling for web vs mobile
      String? redirectUrl;
      
      if (kIsWeb) {
        // For web, use the current origin with /login-callback path
        redirectUrl = '${Uri.base.origin}/login-callback';
      } else {
        // For mobile, use a deep link scheme
        redirectUrl = 'com.campuscare://login-callback';
      }
      
      // Updated for Supabase Flutter 2.9.0
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        scopes: 'email profile',
      );

      // In Supabase Flutter 2.9.0, signInWithOAuth doesn't return a value
      // It just initiates the OAuth flow
      _isLoading = false;
      notifyListeners();
      return true;
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
