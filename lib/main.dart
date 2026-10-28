import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'services/auth/auth_service.dart';
import 'services/auth/local_auth_service.dart';
import 'services/auth/supabase_auth_service.dart';
import 'services/local_vocabulary_repository.dart';
import 'services/supabase_vocabulary_repository.dart';
import 'services/vocabulary_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final AuthService auth;
  final VocabularyRepository Function(AppUser user) repositoryFor;

  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
    final client = Supabase.instance.client;
    auth = SupabaseAuthService(client);
    repositoryFor = (_) => SupabaseVocabularyRepository(client);
  } else {
    // Sin Supabase: modo local, sin cuentas; todo queda en este dispositivo.
    auth = LocalAuthService();
    repositoryFor = (user) => LocalVocabularyRepository(prefs, scope: user.id);
  }

  runApp(GridLearnApp(auth: auth, prefs: prefs, repositoryFor: repositoryFor));
}
