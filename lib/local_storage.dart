import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class LocalStorage {
  static const String fileName = "patients_data.json";

  static Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/$fileName");
  }

  // Make sure the local file exists; copy from asset if it doesn't
  static Future<List<dynamic>> readPatients() async {
    final file = await _getLocalFile();
    if (!await file.exists()) {
      // Copy from assets if file is missing
      final assetData =
          await rootBundle.loadString('assets/patients_data.json');
      await file.writeAsString(assetData);
    }
    final contents = await file.readAsString();
    return json.decode(contents);
  }

  static Future<void> writePatients(List<dynamic> patients) async {
    final file = await _getLocalFile();
    await file.writeAsString(jsonEncode(patients));
    print("✅ Updated patients data at ${file.path}");
  }
}
