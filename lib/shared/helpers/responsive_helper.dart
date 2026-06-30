import 'package:flutter/material.dart';

import '../constants/app_breakpoints.dart';

/// Clase auxiliar para determinar el tipo de dispositivo
/// según el ancho disponible.
class ResponsiveHelper {
  ResponsiveHelper._();

  /// Indica si la pantalla corresponde a un teléfono.
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < AppBreakpoints.mobile;
  }

  /// Indica si la pantalla corresponde a una tablet.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return width >= AppBreakpoints.mobile && width < AppBreakpoints.tablet;
  }

  /// Indica si la pantalla corresponde a escritorio.
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppBreakpoints.tablet;
  }
}
