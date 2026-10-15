import 'package:flutter/widgets.dart';

/// Llave del Navigator raíz. Sirve para mostrar overlays (como el popup de logros locales)
/// desde código que no tiene un BuildContext a mano.
final rootNavigatorKey = GlobalKey<NavigatorState>();
