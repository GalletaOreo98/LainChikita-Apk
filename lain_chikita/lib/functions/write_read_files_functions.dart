import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../global_vars.dart';

Future<void> writeAThankUTxt() async {
  Directory? directory;
  if (platformName == "android") {
    directory = await getExternalStorageDirectory();
  } else {
    directory = await getApplicationDocumentsDirectory();
  }
  directory!.path;
  Directory outputDir = await Directory("${directory.path}/README").create();
  final File file = File('${outputDir.path}/my_file.txt');
  await file.writeAsString("Gracias por instalar lain_chikita, amable senior $username");
}
