import 'dart:convert' show json;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:games_services/games_services.dart';

import '../global_vars.dart' as gv;
import 'encryption_functions.dart';
import '../private_keys.dart';
import 'gacha_functions.dart';

const secretKey = SECRET_KEY;

Future<String> redeemCode(String encryptedCode) async {
  String resultMessage = "invalid_code";
  try {
    String decryptedCodeToRedeem = decryptData(encryptedCode, secretKey);
    Map<String, dynamic> codeToRedeem = Map<String, dynamic>.from(json.decode(decryptedCodeToRedeem)); 

    //Verificar si usa Google Play Games, si no, no puede canjear codigos
    final isSignedIn = await GameAuth.isSignedIn;
    if (!isSignedIn) return resultMessage;
 
    //Cargar lista de codigos ya canjeados desde el almacenamiento de Google Play Games
    try {
      await GameAuth.signIn();
      final redeemedCodesCloudData = await SaveGame.loadGame(name: "redeemed_codes");
      if (redeemedCodesCloudData != null) {
        if (kDebugMode) debugPrint('Loaded redeemed codes data: $redeemedCodesCloudData');
        List<String> redeemedCodesList = List<String>.from(json.decode(redeemedCodesCloudData));
        //Actualizar la variable global de codigos canjeados
        gv.redeemedCodes = redeemedCodesList;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading redeemed codes: $e');
    }

    //Verificar si el codigo ya fue canjeado
    if (gv.redeemedCodes.contains(codeToRedeem['id'])) {
      return "already_redeemed";
    }

    for (var redeemableCodeElement in gv.redeemableCodes) {

      if (redeemableCodeElement['id'] == codeToRedeem['id']) {
        //Proveniente de la lista de codigos canjeables disponibles en la app (global_vars)
        dynamic codeValueData = redeemableCodeElement['value'];

        final codeType = gv.RedeemableCodeType.values.firstWhere(
          (e) => e.name == redeemableCodeElement['type'],
          orElse: () => gv.RedeemableCodeType.unknown,
        );
        // No se ocupa el .name porque ya se comparó en el firstWhere
        switch (codeType) {
          case gv.RedeemableCodeType.accessory:
            //Agregar accesorio especifico al inventario
            bool wasSuccess = unlockAccessoryByName(codeValueData as String);
            if (wasSuccess) {
              resultMessage = "accessory_unlocked $codeValueData";
            } else {
                resultMessage = "accessory_already_unlocked $codeValueData";
              }
            break;
          case gv.RedeemableCodeType.randomAccessory:
            bool wasSuccess = unlockRandomAccessory();
            if (wasSuccess) {
              String accessoryName = gv.inventory.last['name'] as String;
              resultMessage = "accessory_unlocked $accessoryName";
            } else {
                resultMessage = "cannot_unlock_more_accessories";
              }
            break;
          case gv.RedeemableCodeType.coin:
            //Agregar monedas
            //gv.coins += codeValueData as int;
            break;
          case gv.RedeemableCodeType.changeName:
            //Permitir cambio de nombre
            //canChangeName = true;
            break;
          default:
            //Tipo desconocido
            break;
        }
        //Agregar a la lista de codigos canjeados
        gv.redeemedCodes.add(redeemableCodeElement['id'] as String);
        if (kDebugMode) debugPrint('Redeemed codes after redeeming: ${gv.redeemedCodes}');
        await _cleanDeprecatedRedeemedCodes();
        if (kDebugMode) debugPrint('Redeemed codes after cleaning: ${gv.redeemedCodes}');
        await _updateRedeemedCodes();
        break;
      }
    }
    return resultMessage;
  } catch (e) {
    return resultMessage;
  }
}

/// Actualiza la lista de codigos canjeados en el almacenamiento de Google Play Games
Future<void> _updateRedeemedCodes() async {
  try {
    String redeemedCodesListJson = json.encode(gv.redeemedCodes);
    if (kDebugMode) debugPrint('Updating redeemed codes data: $redeemedCodesListJson');
    await GameAuth.signIn();
    await SaveGame.saveGame(
      name: "redeemed_codes",
      data: redeemedCodesListJson,
    );
  } catch (e) {
    if (kDebugMode) debugPrint('Error updating redeemed codes: $e');
  }
}

/// Limpiar los redeemedCodes que ya no estan en redeemableCodes
Future<void> _cleanDeprecatedRedeemedCodes() async {
  gv.redeemedCodes.removeWhere((redeemedCodeId) =>
      !gv.redeemableCodes.any((redeemableCode) => redeemableCode['id'] == redeemedCodeId));
}