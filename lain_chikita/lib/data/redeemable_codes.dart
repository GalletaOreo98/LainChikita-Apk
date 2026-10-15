enum RedeemRewardType {
  /// Desbloquea un accesorio específico ([RedeemableCode.accessoryId])
  accessory,

  /// Desbloquea un accesorio al azar de los que faltan
  randomAccessory,
}

class RedeemableCode {
  const RedeemableCode.accessory(this.id, String this.accessoryId) : type = RedeemRewardType.accessory;
  const RedeemableCode.randomAccessory(this.id)
      : type = RedeemRewardType.randomAccessory,
        accessoryId = null;

  final String id;
  final RedeemRewardType type;
  final String? accessoryId;
}

/// Códigos canjeables vigentes. El usuario introduce el código encriptado (JSON `{"id": ...}`
/// encriptado con SECRET_KEY) y aquí se busca qué recompensa da ese id.
///
/// Si quitas un código de esta lista, también se limpia de la lista de canjeados del usuario
/// la próxima vez que canjee algo.
const List<RedeemableCode> redeemableCodes = [
  RedeemableCode.accessory('26112025A', 'christmas_cane'),
  RedeemableCode.accessory('26112025B', 'nerd_glasses'),
  RedeemableCode.randomAccessory('26112025C'),
  RedeemableCode.accessory('24042026A', 'nyan_cat'),
];
