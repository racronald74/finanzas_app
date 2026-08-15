import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                child: Column(
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 12),
                    _buildOptionCard(
                      icon: Icons.account_balance_outlined,
                      iconColor: const Color(0xFFFFB52E),
                      iconBackground: const Color(0xFFFFEDC9),
                      title: 'Deudas',
                      description: 'Gestiona tus deudas y\ncontrola tus pagos.',
                    ),
                    const SizedBox(height: 8),
                    _buildOptionCard(
                      icon: Icons.calendar_month_outlined,
                      iconColor: const Color(0xFF16B86A),
                      iconBackground: const Color(0xFFD7F3E5),
                      title: 'Obligaciones',
                      description: 'Administra tus obligaciones\nmensuales.',
                    ),
                    const SizedBox(height: 8),
                    _buildOptionCard(
                      icon: Icons.bar_chart_rounded,
                      iconColor: const Color(0xFF8B3DFF),
                      iconBackground: const Color(0xFFE9D9FF),
                      title: 'Reportes',
                      description:
                          'Visualiza reportes y análisis\nde tus finanzas.',
                    ),
                    const SizedBox(height: 8),
                    _buildOptionCard(
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

  Widget _buildWelcomeSection() {
    return SizedBox(
      height: 116,
      child: Row(
        children: [
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hola, Ronald',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF303030),
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Explora más herramientas\nde tu gestión financiera.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.25,
                      color: Color(0xFF303030),
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

  Widget _buildOptionCard({
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
        onTap: () {},
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
