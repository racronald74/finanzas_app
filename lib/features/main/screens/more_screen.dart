import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_background.dart';

class MoreScreen extends StatelessWidget {
  /// Acción para abrir la pantalla de Obligaciones.
  final VoidCallback? onObligationsPressed;

  const MoreScreen({super.key, this.onObligationsPressed});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final usuario = authProvider.currentUser;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AppBackground(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                  child: Column(
                    children: [
                      _buildWelcomeSection(usuario?.nombre ?? 'Usuario'),
                      const SizedBox(height: 12),
                      _buildOptionCard(
                        context,
                        icon: Icons.account_balance_outlined,
                        iconColor: const Color(0xFFFFB52E),
                        iconBackground: const Color(0xFFFFEDC9),
                        title: 'Deudas',
                        description:
                            'Gestiona tus deudas y\ncontrola tus pagos.',
                      ),
                      const SizedBox(height: 8),
                      _buildOptionCard(
                        context,
                        icon: Icons.account_balance_outlined,
                        iconColor: const Color(0xFF16B86A),
                        iconBackground: const Color(0xFFD7F3E5),
                        title: 'Obligaciones',
                        description: 'Administra tus obligaciones\nmensuales.',
                      ),
                      const SizedBox(height: 8),
                      _buildOptionCard(
                        context,
                        icon: Icons.bar_chart_rounded,
                        iconColor: const Color(0xFF8B3DFF),
                        iconBackground: const Color(0xFFE9D9FF),
                        title: 'Reportes',
                        description:
                            'Visualiza reportes y análisis\nde tus finanzas.',
                      ),
                      const SizedBox(height: 8),
                      _buildOptionCard(
                        context,
                        icon: Icons.notifications_none_rounded,
                        iconColor: const Color(0xFFFF5252),
                        iconBackground: const Color(0xFFFFDADA),
                        title: 'Notificaciones',
                        description:
                            'Configura alertas y revisa tu\nhistorial de notificaciones.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 82,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      alignment: Alignment.bottomLeft,
      color: const Color(0xFF3F73BC),
      child: const Text(
        'Más',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String nombre) {
    return SizedBox(
      height: 116,
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hola, $nombre',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF17324D),
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Explora más herramientas\nde tu gestión financiera.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.25,
                      color: Color(0xFF355C7D),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 88,
            height: 88,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFBE3D),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 46,
              color: Color(0xFF99542F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String description,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onObligationsPressed,
        child: SizedBox(
          height: 78,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171717),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 29,
                  color: Color(0xFF202020),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
