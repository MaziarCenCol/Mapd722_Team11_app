import 'package:flutter/material.dart';

class AddClinicalScreen extends StatefulWidget {
  final String patientId;

  const AddClinicalScreen({super.key, required this.patientId});

  @override
  _AddClinicalScreenState createState() => _AddClinicalScreenState();
}

class _AddClinicalScreenState extends State<AddClinicalScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _bphController = TextEditingController();
  TextEditingController _bplController = TextEditingController();
  TextEditingController _hbrController = TextEditingController();
  TextEditingController _rrController = TextEditingController();
  TextEditingController _bolController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Clinical Record')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _bphController,
                decoration:
                    InputDecoration(labelText: 'Blood Pressure (Systolic)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter systolic blood pressure';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _bplController,
                decoration:
                    InputDecoration(labelText: 'Blood Pressure (Diastolic)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter diastolic blood pressure';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _hbrController,
                decoration: InputDecoration(labelText: 'Heart Rate (bpm)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter heart rate';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _rrController,
                decoration:
                    InputDecoration(labelText: 'Respiratory Rate (bpm)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter respiratory rate';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _bolController,
                decoration:
                    InputDecoration(labelText: 'Blood Oxygen Level (%)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter blood oxygen level';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final newRecord = {
                        'date': DateTime.now().toIso8601String(),
                        'bph': int.parse(_bphController.text),
                        'bpl': int.parse(_bplController.text),
                        'hbr': int.parse(_hbrController.text),
                        'rr': int.parse(_rrController.text),
                        'bol': int.parse(_bolController.text),
                      };

                      Navigator.pop(context,
                          newRecord); // Return to previous screen with new data
                    }
                  },
                  child: Text('Save Clinical Record'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


