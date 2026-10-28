/// Configuración inyectada al compilar con `--dart-define` (ver `env.example.json`).
///
/// La clave anónima de Supabase es pública por diseño: la seguridad real la
/// dan las políticas RLS de la base de datos. Nunca incluyas aquí la clave
/// `service_role`. Sirve la clave "publishable" (`sb_publishable_...`) o la
/// "anon" clásica del panel de Supabase.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Si no hay Supabase configurado, la app funciona en "modo local": sin
  /// cuenta y con los vocabularios guardados solo en este dispositivo.
  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
