import 'dart:convert';
import 'package:flutter/material.dart';
import 'addClinical.dart';
import 'package:intl/intl.dart';
import 'local_storage.dart';

class ViewPatientScreen extends StatefulWidget {
  final String patientId;
  final String caregiverName;
  final int totalPatients;

  const ViewPatientScreen({
    Key? key,
    required this.patientId,
    required this.caregiverName,
    required this.totalPatients,
  }) : super(key: key);

  @override
  _ViewPatientScreenState createState() => _ViewPatientScreenState();
}

class _ViewPatientScreenState extends State<ViewPatientScreen> {
  Map<String, dynamic> patient = {};
  List<dynamic> clinicalHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPatientData();
  }

  // Load the data from the local 'patients_data.json' instead of an API.
  Future<void> fetchPatientData() async {
    final data = await LocalStorage.readPatients();

    final patientData = data.firstWhere(
      (patient) => patient['_id'] == widget.patientId,
      orElse: () => throw Exception('Patient data not found'),
    );

    if (patientData.isNotEmpty) {
      setState(() {
        patient = patientData;
        clinicalHistory = patient['clinical'] ?? [];
        isLoading = false;
      });
    } else {
      throw Exception('Patient data not found');
    }
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
        title: Text('${widget.caregiverName} : (${widget.totalPatients})'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Patient Info Section with Image
                    Card(
                      elevation: 5,
                      margin: EdgeInsets.only(bottom: 16.0),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Patient Image
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: AssetImage(
                                  'assets/images/${patient['image']}'), // Add the image path here
                            ),
                            SizedBox(height: 16),
                            Text(
                              '${patient['name']}',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text('Gender: ${patient['gender']}'),
                            Text('Age: ${calculateAge(patient['bdate'])}'),
                            Text('Email: ${patient['email']}'),
                            Text('Phone: ${patient['phone']}'),
                            Text('Address: ${patient['address']}'),
                          ],
                        ),
                      ),
                    ),

                    // Clinical History Section (No Shadow)
                    clinicalHistory.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Text('No clinical history available.'),
                          )
                        : Column(
                            children: clinicalHistory.map((clinical) {
                              String status = calculateStatus(
                                clinical['rr']?.toDouble() ?? 0,
                                clinical['bol']?.toDouble() ?? 0,
                              );
                              return Card(
                                elevation: 0, // No shadow for clinical history
                                margin: EdgeInsets.only(bottom: 16.0),
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '> ${DateFormat('MMMM dd, yyyy').format(DateTime.parse(clinical['date']))}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                          '(BP) Blood Pressure: ${clinical['bph']}/${clinical['bpl']}'),
                                      Text(
                                          '(HR) Heart Rate: ${clinical['hbr']} bpm'),
                                      Text(
                                        '(RR) Respiratory Rate: ${clinical['rr']} bpm',
                                        style: TextStyle(
                                          color: (clinical['rr'] > 20)
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                      Text(
                                        '(BOL) Blood Oxygen Level: ${clinical['bol']}%',
                                        style: TextStyle(
                                          color: (clinical['bol'] < 90)
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Status: $status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: status == 'Critical'
                                              ? Colors.red
                                              : (status == 'Warning'
                                                  ? Colors.orange
                                                  : Colors.green),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                    // Button to Navigate to Add Clinical
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: FloatingActionButton(
                        onPressed: () async {
                          final newRecord = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddClinicalScreen(
                                  patientId: widget.patientId),
                            ),
                          );

                          if (newRecord != null) {
                            setState(() {
                              clinicalHistory.add(newRecord);
                              patient['clinical'] = clinicalHistory;
                            });

                            final allPatients =
                                await LocalStorage.readPatients();
                            final index = allPatients.indexWhere(
                              (p) => p['_id'] == widget.patientId,
                            );

                            if (index != -1) {
                              allPatients[index] = patient;
                              await LocalStorage.writePatients(allPatients);
                            }
                          }
                        },
                        child: Icon(Icons.add), // "+" icon
                        backgroundColor: Colors.green, // Green background
                        tooltip: 'Add Clinical Record',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
