/// Resultado de intentar canjear un código
sealed class RedeemResult {
  const RedeemResult();
}

class AccessoryUnlocked extends RedeemResult {
  const AccessoryUnlocked(this.accessoryId);
  final String accessoryId;
}

class AccessoryAlreadyOwned extends RedeemResult {
  const AccessoryAlreadyOwned(this.accessoryId);
  final String accessoryId;
}

/// El código era de accesorio aleatorio pero ya no quedan accesorios por desbloquear
class NoAccessoriesLeft extends RedeemResult {
  const NoAccessoriesLeft();
}

class CodeAlreadyRedeemed extends RedeemResult {
  const CodeAlreadyRedeemed();
}

/// Código mal formado, desconocido, o el usuario no tiene sesión en Google Play Games
class InvalidCode extends RedeemResult {
  const InvalidCode();
}
