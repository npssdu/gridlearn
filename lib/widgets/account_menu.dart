import 'package:flutter/material.dart';

import '../services/auth/auth_service.dart';
import '../theme/app_theme.dart';

/// Cuenta de la persona: con Supabase muestra su correo y "Cerrar sesión";
/// en modo local avisa de que los datos solo están en este dispositivo.
class AccountMenu extends StatelessWidget {
  const AccountMenu({
    super.key,
    required this.user,
    required this.requiresLogin,
    required this.onSignOut,
    this.compact = false,
  });

  final AppUser user;
  final bool requiresLogin;
  final VoidCallback onSignOut;

  /// Solo el avatar (sin el correo), para pantallas estrechas.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!requiresLogin) {
      return Tooltip(
        message: 'Modo local: tus vocabularios se guardan solo en este dispositivo.\n'
            'Configura Supabase para activar cuentas y guardado en la nube.',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 14, color: AppColors.slate500),
              SizedBox(width: 4),
              Text(
                'Modo local',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate600),
              ),
            ],
          ),
        ),
      );
    }

    final email = user.email ?? 'Cuenta';
    return PopupMenuButton<String>(
      tooltip: 'Cuenta',
      position: PopupMenuPosition.under,
      onSelected: (_) => onSignOut(),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              email,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate700),
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'signout',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Cerrar sesión'),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
        decoration: BoxDecoration(
          color: AppColors.brand50,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.brand100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.navy,
              child: Text(
                email.characters.first.toUpperCase(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy),
                ),
              ),
            ],
            const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.brand700),
          ],
        ),
      ),
    );
  }
}
