import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Use a getter to ensure we always get the current client
  static SupabaseClient get supabaseClient => Supabase.instance.client;
}
