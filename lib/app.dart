import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth_gate.dart';
import 'services/auth/auth_service.dart';
import 'services/vocabulary_repository.dart';
import 'theme/app_theme.dart';

class GridLearnApp extends StatelessWidget {
  const GridLearnApp({
    super.key,
    required this.auth,
    required this.prefs,
    required this.repositoryFor,
    this.useGoogleFonts = true,
  });

  final AuthService auth;
  final SharedPreferences prefs;
  final VocabularyRepository Function(AppUser user) repositoryFor;
  final bool useGoogleFonts;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GridLearn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(useGoogleFonts: useGoogleFonts),
      home: AuthGate(auth: auth, prefs: prefs, repositoryFor: repositoryFor),
    );
  }
}
