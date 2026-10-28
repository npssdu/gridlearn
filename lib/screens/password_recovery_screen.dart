import 'package:flutter/material.dart';

import '../services/auth/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/brand_logo.dart';
import '../widgets/section_card.dart';

/// Se muestra cuando la persona llega desde el enlace "restablecer contraseña".
class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.updatePassword(_password.text);
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: BrandMark(size: 64)),
                        const SizedBox(height: 12),
                        Text('Nueva contraseña', textAlign: TextAlign.center, style: AppTheme.heading(26)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: const InputDecoration(
                            labelText: 'Nueva contraseña',
                            helperText: 'Mínimo $minPasswordLength caracteres, con letras y números',
                          ),
                          validator: validatePassword,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirm,
                          obscureText: true,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(labelText: 'Repite la contraseña'),
                          validator: (v) => v != _password.text ? 'Las contraseñas no coinciden' : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: Color(0xFFBE123C))),
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
                              : const Text('Guardar contraseña'),
                        ),
                        TextButton(
                          onPressed: _busy ? null : widget.auth.signOut,
                          child: const Text('Cancelar'),
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
    );
  }
}
