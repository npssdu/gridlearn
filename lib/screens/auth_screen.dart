import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/brand_logo.dart';
import '../widgets/section_card.dart';

/// Inicio de sesión y registro con correo y contraseña.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _registering = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _setMode(bool registering) {
    setState(() {
      _registering = registering;
      _error = null;
      _info = null;
      _confirm.clear();
    });
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      if (_registering) {
        final outcome = await widget.auth.signUp(email: _email.text, password: _password.text);
        if (!mounted) return;
        if (outcome == SignUpOutcome.confirmationRequired) {
          setState(() {
            _registering = false;
            _password.clear();
            _confirm.clear();
            _info = 'Si el correo es válido, te enviamos un enlace para confirmar tu cuenta. '
                'Revisa tu bandeja de entrada (y el spam) y luego inicia sesión.';
          });
        }
      } else {
        await widget.auth.signIn(email: _email.text, password: _password.text);
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final problem = validateEmail(_email.text);
    if (problem != null) {
      setState(() {
        _info = null;
        _error = 'Escribe tu correo arriba para enviarte el enlace de recuperación.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await widget.auth.sendPasswordReset(_email.text);
      if (mounted) {
        setState(() {
          _info = 'Si el correo tiene una cuenta, te enviamos un enlace para restablecer la contraseña.';
        });
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SectionCard(
                  padding: 24,
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: BrandLogo(width: 200)),
                          const SizedBox(height: 8),
                          Text(
                            _registering ? 'Crea tu cuenta' : 'Inicia sesión',
                            textAlign: TextAlign.center,
                            style: AppTheme.heading(26),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Guarda tus vocabularios y repásalos cuando quieras.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.slate500),
                          ),
                          const SizedBox(height: 20),
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: false, label: Text('Iniciar sesión')),
                              ButtonSegment(value: true, label: Text('Crear cuenta')),
                            ],
                            selected: {_registering},
                            onSelectionChanged: _busy ? null : (s) => _setMode(s.first),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            autocorrect: false,
                            enableSuggestions: false,
                            inputFormatters: [LengthLimitingTextInputFormatter(254)],
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.mail_outline, size: 20),
                            ),
                            validator: validateEmail,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            textInputAction: _registering ? TextInputAction.next : TextInputAction.done,
                            autofillHints: [
                              _registering ? AutofillHints.newPassword : AutofillHints.password,
                            ],
                            enableSuggestions: false,
                            autocorrect: false,
                            inputFormatters: [LengthLimitingTextInputFormatter(72)],
                            onFieldSubmitted: (_) => _registering ? null : _submit(),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              helperText: _registering
                                  ? 'Mínimo $minPasswordLength caracteres, con letras y números'
                                  : null,
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            // En el inicio de sesión no se valida la fortaleza (solo que no esté vacía).
                            validator: (v) => _registering
                                ? validatePassword(v)
                                : ((v ?? '').isEmpty ? 'Ingresa tu contraseña' : null),
                          ),
                          if (_registering) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirm,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              enableSuggestions: false,
                              autocorrect: false,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                labelText: 'Repite la contraseña',
                                prefixIcon: Icon(Icons.lock_outline, size: 20),
                              ),
                              validator: (v) => v != _password.text ? 'Las contraseñas no coinciden' : null,
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            _Banner(text: _error!, error: true),
                          ],
                          if (_info != null) ...[
                            const SizedBox(height: 12),
                            _Banner(text: _info!, error: false),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brand600,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control)),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(_registering ? 'Crear cuenta' : 'Entrar'),
                          ),
                          if (!_registering)
                            TextButton(
                              onPressed: _busy ? null : _forgotPassword,
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.error});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: error ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Text(
          text,
          style: TextStyle(color: error ? const Color(0xFFBE123C) : const Color(0xFF047857)),
        ),
      ),
    );
  }
}
