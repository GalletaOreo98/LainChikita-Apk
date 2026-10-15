enum ClickVerdict {
  /// Clic normal
  valid,

  /// Clic sospechoso (muy rápido, demasiados por segundo o patrón de autoclicker)
  rejected,

  /// Este clic hizo que se llegara al límite de clics sospechosos y se activó el bloqueo
  triggeredBlock,
}

/// Anti-cheat de clics: detecta clics demasiado rápidos o con patrón de autoclicker.
///
/// No sabe nada de UI ni de timers: quien lo usa decide qué hacer con el veredicto
/// y cuándo llamar a [unblock].
class ClickGuard {
  static const int maxClicksPerSecond = 12;

  /// Mínimo de ms entre clics (previene ráfagas de clics, "picos específicos")
  static const int minClickIntervalMs = 80;

  /// Al llegar a este número de clics sospechosos se activa el bloqueo
  static const int maxSuspiciousClicks = 20;

  /// Si los intervalos entre clics varían menos que esto (y son rápidos), parece autoclicker
  static const int _autoclickerMaxDeviationMs = 10;
  static const int _autoclickerMaxAvgIntervalMs = 200;
  static const int _autoclickerMinSamples = 5;

  final List<int> _recentClickTimes = [];
  int _lastClickTime = 0;
  int _suspiciousClickCount = 0;
  bool _isBlocked = false;

  bool get isBlocked => _isBlocked;
  int get suspiciousClickCount => _suspiciousClickCount;

  /// Registra un clic hecho en [nowMs] (milisegundos desde epoch) y dice si es válido
  ClickVerdict check(int nowMs) {
    if (_isBlocked) return ClickVerdict.rejected;

    if (_lastClickTime > 0 && nowMs - _lastClickTime < minClickIntervalMs) {
      return _registerSuspicious(1);
    }

    // Solo nos interesan los clics del último segundo
    _recentClickTimes.removeWhere((time) => nowMs - time > 1000);

    if (_recentClickTimes.length >= maxClicksPerSecond) {
      return _registerSuspicious(1);
    }

    if (_looksLikeAutoclicker()) {
      // Los patrones regulares se penalizan más
      return _registerSuspicious(2);
    }

    _recentClickTimes.add(nowMs);
    _lastClickTime = nowMs;
    // El comportamiento normal va "perdonando" los clics sospechosos
    if (_suspiciousClickCount > 0) _suspiciousClickCount--;
    return ClickVerdict.valid;
  }

  /// Quita el bloqueo y reinicia el contador de clics sospechosos
  void unblock() {
    _isBlocked = false;
    _suspiciousClickCount = 0;
  }

  ClickVerdict _registerSuspicious(int penalty) {
    _suspiciousClickCount += penalty;
    if (_suspiciousClickCount >= maxSuspiciousClicks) {
      _isBlocked = true;
      return ClickVerdict.triggeredBlock;
    }
    return ClickVerdict.rejected;
  }

  bool _looksLikeAutoclicker() {
    if (_recentClickTimes.length < _autoclickerMinSamples) return false;

    final intervals = [
      for (var i = 1; i < _recentClickTimes.length; i++) _recentClickTimes[i] - _recentClickTimes[i - 1],
    ];
    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    final maxDeviation = intervals.map((interval) => (interval - avgInterval).abs()).reduce((a, b) => a > b ? a : b);

    return maxDeviation < _autoclickerMaxDeviationMs && avgInterval < _autoclickerMaxAvgIntervalMs;
  }
}
