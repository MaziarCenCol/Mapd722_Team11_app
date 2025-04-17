import 'package:flutter/material.dart';
import 'local_storage.dart'; // Import the local_storage helper to read/write patient data

class PatientProvider extends ChangeNotifier {
  List<dynamic> patients = [];

  Future<void> loadPatients() async {
    patients = await LocalStorage.readPatients();
    notifyListeners();
  }

  Future<void> savePatients() async {
    await LocalStorage.writePatients(patients);
  }

  void addPatient(Map<String, dynamic> newPatient) {
    patients.add(newPatient);
    savePatients();  // Optionally save to storage
    notifyListeners();
  }

  void removePatient(String patientId) {
    patients.removeWhere((patient) => patient['id'] == patientId);
    savePatients();  // Optionally save to storage
    notifyListeners();
  }

 void addClinicalRecord(String patientId, Map<String, dynamic> record) {
  final index = patients.indexWhere((p) => p['_id'] == patientId);
  if (index != -1) {
    if (patients[index]['clinical'] == null) {
      patients[index]['clinical'] = [];
    }
    patients[index]['clinical'].add(record);
    savePatients(); // Persist changes
    notifyListeners(); // Notify UI
  }
}

}
 
