import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' show json, jsonDecode;

//My imports
import '../functions/encryption_functions.dart';
import '../functions/gacha_functions.dart';
import '../global_vars.dart';
import '../private_keys.dart';

const secretKey = SECRET_KEY;

class GachaScreen extends StatefulWidget {
  final Function callback;

  const GachaScreen({super.key, required this.callback});

  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends State<GachaScreen> {
  /// Avisa si ya se copio el texto en la clipboard
  String _copiedText = '';

  String _userName = '';
  String _uuid = '';
  List<Map<String, dynamic>> _unlockedInventory = [];

  //Strings de utilidad para almacenar lo que escribe el usuario en las cajas de texto
  final TextEditingController _publicDataTEC = TextEditingController(text: '');
  final TextEditingController _claimTicketDataTEC = TextEditingController(text: '');

  /// Texto informativo sobre las acciones realizadas
  String _informativeText = '';
  Color _informativeTextColor = appColors.informativeText;
  bool _showTicketEData = false;
  String _ticketEData = '';
  bool _showClaimTicket = false;
  void Function()? _buyTicket;
  /* El flujo de comprar un ticket se basa en:
    1. _copyMyData() #Para copiar nuestra data nada más, si es para regalar no es necesario este paso, ya que el otro user nos la da su data
    2. _setPublicDataToUse(String publicData) #Se verifica la data que copiamos en el campo (nuestra, o de alguien mas)
    3. _readyToBuyTicket() #Gestiona si se esta comprando ticket para uno mismo o para alguien más
    4. buyTicket() || buyTicketFor(_unlockedInventory) #Dependiendo de si es para nosotros o para alguien mas
       #Se nos agrega el item en el inventario o se da el codigo encriptado para copiar y regalarlo
       #encrypt data es `jsonItem + "&" + _uuid` por lo que hay que separarlo por `&` para reclamar el ticket
  */

  // No hace falta optimizar pero se podria
  void hideInformativeText(String element, int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      setState(() {
        if (_copiedText == element) _copiedText = '';
        if (_informativeText == element) _informativeText = '';
      });
    });
  }

  void _claimTicket(String ticketToClaim) {
    // encrypt data es `jsonItem + "&" + _uuid`
    setState(() {
      //_informativeTextColor = appColors.informativeText;
      try {
        String decryptedItem = decryptData(ticketToClaim, secretKey);
        List<String> parts = decryptedItem.split('&');
        if (parts.length == 2) {
          String jsonItem = parts[0];
          String uuid = parts[1];
          if (uuid != userUuid) {
            _informativeText = languageDataManager.getLabel('cannot-be-claimed');
            return;
          }
          Map<String, dynamic> item = Map<String, dynamic>.from(json.decode(jsonItem));
          Map<String, dynamic> inInventory = inventory.firstWhere(
            (element) => element.values.first == item.values.first, //element['name'] == item['name']
            orElse: () => {},
          );
          if (inInventory.isEmpty) {
            unlockedInventory.removeWhere((element) => element['name'] == item['name']);
            inventory.add(item);
            _informativeText = languageDataManager.getLabel('ticket-successfully-claimed');
            _saveInventaries();
          } else {
            _informativeText = languageDataManager.getLabel('already-have-this-item');
          }
        } else {
          _informativeText = languageDataManager.getLabel('cannot-be-claimed');
        }
      } catch (e) {
        _informativeTextColor = appColors.errorText;
        _informativeText = languageDataManager.getLabel('error-invalid-data');
      }
    });
  }

  void _copyTicketEData() {
    Clipboard.setData(ClipboardData(text: _ticketEData));
    setState(() {
      _showTicketEData = false;
      _informativeText = languageDataManager.getLabel('ticket-data-has-been-copied');
    });
  }

  void _copyMyData() async {
    // Formateo de la data necesaria a encriptar
    final jsonUnlockedInventory = json.encode(unlockedInventory);
    final jsonData =
        json.encode({'userName': userName, 'userUuid': userUuid, 'unlockedInventory': jsonUnlockedInventory});
    final encryptedData = encryptData(jsonData, secretKey);
    // Copiar la data ya encriptada al clipboard
    Clipboard.setData(ClipboardData(text: encryptedData));
    setState(() {
      _copiedText = languageDataManager.getLabel('clipboard-is-copied');
      hideInformativeText(_copiedText, 2);
    });
  }

  void _saveInventaries() {
    // Llamada a la función de callback
    widget.callback();
  }

  void _readyToBuyTicket() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _informativeTextColor = appColors.informativeText;
      _informativeText = "${languageDataManager.getLabel('ticket-for')}: $_userName";
    });
    _buyTicket = () {
      setState(() {
        if (userUuid == _uuid) {
          bool isDone = buyTicket();
          isDone
              ? _informativeText = languageDataManager.getLabel('ticket-purchased')
              : _informativeText = languageDataManager.getLabel('cannot-be-purchased');
          prefs.setInt('coins', coins);
          _saveInventaries();
        } else {
          String jsonItem = buyTicketFor(_unlockedInventory);
          if (jsonItem.isNotEmpty) {
            /* Se le concatena el uuid del usuario (separado por un &) para quien se compro (como regalo) el ticket
               para que solo el pueda reclamarlo */
            String encryptedItem =
                // ignore: prefer_interpolation_to_compose_strings
                encryptData(jsonItem + "&" + _uuid, secretKey);
            //debugPrint(encryptedItem);
            _ticketEData = encryptedItem;
            _showTicketEData = true;
            _informativeText = languageDataManager.getLabel('ticket-purchased');
            prefs.setInt('coins', coins);
            _saveInventaries();
          } else {
            _informativeText = languageDataManager.getLabel('cannot-be-purchased');
          }
        }
        _buyTicket = null;
      });
    };
  }

  void _setPublicDataToUse(String publicData) async {
    String decryptedData;
    try {
      decryptedData = decryptData(publicData, secretKey);
      Map<String, String> decryptedDataMap = Map<String, String>.from(json.decode(decryptedData));
      _userName = decryptedDataMap['userName'] ?? '';
      _uuid = decryptedDataMap['userUuid'] ?? '';
      _unlockedInventory = List<Map<String, dynamic>>.from(jsonDecode(decryptedDataMap['unlockedInventory'] ?? '[{}]'));
      _readyToBuyTicket();
    } catch (e) {
      setState(() {
        _buyTicket = null;
        _informativeTextColor = appColors.errorText;
        _informativeText = languageDataManager.getLabel('error-invalid-data');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: appColors.background,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            //Con SingleChildScrollView si el texto es muy grande y no cabe en la pantalla, el usuario pueda hacer scroll para seguir viendo
            child: SingleChildScrollView(
                child: Column(
              children: [
                const SizedBox(height: 16),
                Table(
                    //border: TableBorder.all(), // Borde para la tabla (opcional)
                    children: [
                      TableRow(
                        children: [
                          TableCell(
                            child: Image.asset(
                              'assets/images/coin.png',
                              width: 32,
                              height: 32,
                              alignment: Alignment.centerRight,
                            ),
                          ),
                          TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Text(' x: $coins',
                                  style: TextStyle(
                                    fontSize: 25.0,
                                    color: appColors.primaryText,
                                  )))
                        ],
                      ),
                    ]),
                const SizedBox(height: 16),
                Text('${languageDataManager.getLabel('unlocked-skins')} x ${unlockedInventory.length}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25.0,
                      color: appColors.primaryText,
                    )),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(380, 80),
                      backgroundColor: appColors.secondaryBtn, padding: const EdgeInsets.all(20.0)),
                  onPressed: () => setState(() {
                    _showClaimTicket = true;
                  }),
                  child: Text(languageDataManager.getLabel('redeem-code'),
                      style: const TextStyle(fontSize: 34.0), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(380, 80),
                        backgroundColor: appColors.secondaryBtn, padding: const EdgeInsets.all(20.0)),
                    onPressed: _copyMyData,
                    child: Text(languageDataManager.getLabel('copy-my-public-data'),
                        style: const TextStyle(
                          fontSize: 34.0,
                        ),
                        textAlign: TextAlign.center)),
                const SizedBox(height: 1),
                Text(
                  _copiedText,
                  style: TextStyle(fontSize: 25.0, color: appColors.informativeText, fontStyle: FontStyle.italic),
                ),
                if (_showClaimTicket)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      //Textbox de "Pegar datos de ticket a reclamar"
                      TextField(
                        controller: _claimTicketDataTEC,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: appColors.userInputText, fontSize: 35.0),
                        decoration: InputDecoration(
                            suffixIcon: IconButton(
                              onPressed: () => {
                                _claimTicket(_claimTicketDataTEC.text),
                                _claimTicketDataTEC.clear(),
                                FocusManager.instance.primaryFocus?.unfocus()
                              },
                              icon: const Icon(Icons.done),
                              color: appColors.userInputText
                            ),
                            labelText: languageDataManager.getLabel('ticket-data'),
                            labelStyle: TextStyle(color: appColors.primaryText, fontSize: 20),
                            floatingLabelAlignment: FloatingLabelAlignment.center,
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: appColors.focusItem)),
                            enabledBorder:
                                UnderlineInputBorder(borderSide: BorderSide(color: appColors.userInputText))),
                        onSubmitted: (value) => setState(() {_claimTicket(value);}),
                        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                //Textbox de "Pegar datos publicos"
                TextField(
                  controller: _publicDataTEC,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: appColors.userInputText, fontSize: 35.0),
                  decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: () => {
                          _setPublicDataToUse(_publicDataTEC.text),
                          _publicDataTEC.clear(),
                          FocusManager.instance.primaryFocus?.unfocus()
                        },
                        icon: const Icon(Icons.done),
                        color: appColors.userInputText
                      ),
                      labelText: languageDataManager.getLabel('paste-public-data'),
                      labelStyle: TextStyle(color: appColors.primaryText, fontSize: 20),
                      floatingLabelAlignment: FloatingLabelAlignment.center,
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: appColors.focusItem)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: appColors.userInputText))),
                  onSubmitted: (value) => setState(() {_setPublicDataToUse(value);}),
                  onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: appColors.primaryBtn, padding: const EdgeInsets.all(20.0)),
                  onPressed: _buyTicket,
                  child: Text(languageDataManager.getLabel('buy'), style: const TextStyle(fontSize: 34.0)),
                ),
                const SizedBox(height: 16),
                Text(
                  _informativeText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25.0,
                    color: _informativeTextColor,
                  ),
                ),
                if (_showTicketEData)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: appColors.primaryBtn, padding: const EdgeInsets.all(20.0)),
                        onPressed: _copyTicketEData,
                        child: Text(languageDataManager.getLabel('copy-ticket-data'),
                            style: const TextStyle(fontSize: 34.0)),
                      ),
                    ],
                  )
              ],
            ))));
  }
}
