import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart'; // Add intl to pubspec.yaml
import 'local_storage.dart';

class AddPatientScreen extends StatefulWidget {
  final String caregiverId;

  const AddPatientScreen({super.key, required this.caregiverId});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void savePatient() async {
    if (_formKey.currentState!.validate()) {
      final patients = await LocalStorage.readPatients();
      final newPatient = {
        "_id": const Uuid().v4(),
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "bdate": _selectedDate?.toIso8601String() ?? '',
        "gender": _selectedGender ?? '',
        "address": addressController.text.trim(),
        "status": "normal",
        "image": "default.jpg",
        "user_id": widget.caregiverId,
        "clinical": []
      };
      patients.add(newPatient);
      await LocalStorage.writePatients(patients);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Patient')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val!.isEmpty ? 'Enter name' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (val) => val!.isEmpty ? 'Enter email' : null,
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (val) => val!.isEmpty ? 'Enter phone' : null,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _pickDate,
                child: Text(
                  _selectedDate == null
                      ? 'Select Birthdate'
                      : 'Birthdate: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                ),
              ),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                hint: const Text("Select Gender"),
                items: _genderOptions.map((gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) => setState(() => _selectedGender = value),
                validator: (value) => value == null ? 'Select gender' : null,
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (val) => val!.isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: savePatient,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
