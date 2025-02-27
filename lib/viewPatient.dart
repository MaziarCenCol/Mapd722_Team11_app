import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'addClinical.dart';

class ViewPatientScreen extends StatefulWidget {
  final String patientId;

  const ViewPatientScreen({super.key, required this.patientId});

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

  Future<void> fetchPatientData() async {
    final response = await http.get(Uri.parse(
        'http://localhost:5000/api/patient/patients/${widget.patientId}'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        patient = data;
        clinicalHistory = patient['clinical'] ?? [];
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load patient data');
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
      appBar: AppBar(title: Text('Patient Details')),
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
                                        'Clinical Test ${clinical['date']}',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
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
                        onPressed: () {
                          // Navigate to the AddClinicalScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddClinicalScreen(
                                  patientId: widget.patientId),
                            ),
                          );
                        },
                        child: Icon(Icons.add),  // "+" icon
                        backgroundColor: Colors.green,  // Green background
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
