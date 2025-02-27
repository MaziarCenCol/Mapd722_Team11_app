import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//import 'package:intl/intl.dart';
import 'addPatient.dart';
import 'viewPatient.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient List',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PatientListScreen(),
    );
  }
}

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List patients = [];
  List filteredPatients = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    final response =
        await http.get(Uri.parse('http://localhost:5000/api/patient/patients'));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      setState(() {
        patients = data;
        filteredPatients = data; // Initialize with all patients
      });
    } else {
      throw Exception('Failed to load patients');
    }
  }

  void filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredPatients = patients;
      } else {
        filteredPatients = patients.where((patient) {
          return patient['name'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String calculateAge(String birthDateString) {
    DateTime birthDate = DateTime.parse(birthDateString);
    int age = DateTime.now().year - birthDate.year;
    if (DateTime.now().month < birthDate.month ||
        (DateTime.now().month == birthDate.month &&
            DateTime.now().day < birthDate.day)) {
      age--;
    }
    return '$age yrs';
  }

  String calculateStatus(double rr, double bol) {
    if ((rr >= 12 && rr <= 20) && bol >= 90) {
      return 'Normal';
    } else if ((rr < 12 || rr > 20) && (bol >= 90 && bol <= 95)) {
      return 'Warning';
    } else {
      return 'Critical';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Patient List'),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddPatientScreen()),
                );
              },
              icon: Icon(Icons.add, size: 20),
              label: Text("Add Patient"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by Name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onChanged: (query) => filterPatients(query),
            ),
          ),
          Expanded(
            child: filteredPatients.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      var patient = filteredPatients[index];
                      var lastClinical = patient['clinical'].isNotEmpty
                          ? patient['clinical'].last
                          : null;

                      String status = 'Normal';
                      if (lastClinical != null) {
                        double rr = lastClinical['rr']?.toDouble() ?? 0;
                        double bol = lastClinical['bol']?.toDouble() ?? 0;
                        status = calculateStatus(rr, bol);
                      }

                      return Card(
                        margin: EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundImage:
                                AssetImage('assets/images/${patient['image']}'),
                          ),
                          title:
                              Text('${patient['name']} (${patient['gender']})'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Age: ${calculateAge(patient['bdate'])}'),
                              Text('Status: $status',
                                  style: TextStyle(
                                      color: status == 'Critical'
                                          ? Colors.red
                                          : (status == 'Warning'
                                              ? Colors.orange
                                              : Colors.green),
                                      fontWeight: FontWeight.bold)),
                              if (lastClinical != null) ...[
                                Text(
                                    '(BP) Blood Pressure : ${lastClinical['bph']}/${lastClinical['bpl']}'),
                                Text(
                                    '(HR) Heart Rate : ${lastClinical['hbr']} bpm'),
                                Text(
                                  '(RR) Respiratory Rate : ${lastClinical['rr']} bpm',
                                  style: TextStyle(
                                    color: (lastClinical['rr'] > 20)
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                                Text(
                                  '(BOL) Blood Oxygen Level : ${lastClinical['bol']}%',
                                  style: TextStyle(
                                    color: (lastClinical['bol'] < 90)
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          onTap: () {
                            String? patientId = patient[
                                '_id']; // Ensure the patient ID is not null
                            if (patientId != null) {
                              // Navigate to the ViewPatientScreen passing the patient ID
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ViewPatientScreen(patientId: patientId),
                                ),
                              );
                            } else {
                              // Handle the case where the patient ID is null, e.g., show an error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("Patient ID is missing")),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
