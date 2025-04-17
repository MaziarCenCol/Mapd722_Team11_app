import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'addPatient.dart';
import 'viewPatient.dart';
import 'patient_provider.dart'; // Import the provider

class PatientListScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const PatientListScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

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
    // Loading patients from the provider instead of LocalStorage
    _loadPatients();
  }

  // Load patient data from Provider
  Future<void> _loadPatients() async {
    final provider = Provider.of<PatientProvider>(context, listen: false);
    await provider.loadPatients(); // Load patients from the provider
    setState(() {
      patients = provider.patients;
      filteredPatients = patients
          .where((p) => p['user_id'] == widget.userId)
          .toList(); // Show only patients for this caregiver
    });
  }

  // Filter patients based on search query
  void filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredPatients =
            patients.where((p) => p['user_id'] == widget.userId).toList();
      } else {
        filteredPatients = patients.where((patient) {
          return patient['user_id'] == widget.userId &&
              patient['name'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // Calculate the patient's age
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

  // Determine status
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
            Text(
              '${widget.userName} : (${filteredPatients.length})',
              style: TextStyle(fontSize: 16),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh Patient List',
                  onPressed: _loadPatients,
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddPatientScreen(caregiverId: widget.userId),
                      ),
                    );
                    if (result == true) {
                      _loadPatients(); // Reload after adding new patient
                    }
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
              onChanged: filterPatients,
            ),
          ),
          Expanded(
            child: filteredPatients.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      var patient = filteredPatients[index];
                      var lastClinical = (patient['clinical'] != null &&
                              patient['clinical'].isNotEmpty)
                          ? patient['clinical'].last
                          : null;

                      String status = 'Normal';
                      if (lastClinical != null) {
                        double rr = (lastClinical['rr'] ?? 0).toDouble();
                        double bol = (lastClinical['bol'] ?? 0).toDouble();
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
                            String patientId = patient['_id'].toString();
                            if (patientId != '') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewPatientScreen(
                                    patientId: patientId,
                                    caregiverName: widget.userName,
                                    totalPatients: filteredPatients.length,
                                  ),
                                ),
                              );
                            } else {
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