import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../models/patient_model.dart';

class EditPatientInformationScreen extends StatefulWidget {
  final PatientModel patient;

  const EditPatientInformationScreen({
    Key? key,
    required this.patient,
  }) : super(key: key);

  @override
  _EditPatientInformationScreenState createState() =>
      _EditPatientInformationScreenState();
}

class _EditPatientInformationScreenState
    extends State<EditPatientInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _emergencyContactController;
  final List<TextEditingController> _allergyControllers = [];
  final List<TextEditingController> _historyControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.patient.name);
    _emailController = TextEditingController(text: widget.patient.email);
    _phoneController =
        TextEditingController(text: widget.patient.phoneNumber ?? '');
    _bloodGroupController =
        TextEditingController(text: widget.patient.bloodGroup);
    _emergencyContactController =
        TextEditingController(text: widget.patient.emergencyContact);

    // Initialize allergy controllers
    for (String allergy in widget.patient.allergies) {
      _allergyControllers.add(TextEditingController(text: allergy));
    }
    if (_allergyControllers.isEmpty) {
      _allergyControllers.add(TextEditingController());
    }

    // Initialize medical history controllers
    for (String history in widget.patient.medicalHistory) {
      _historyControllers.add(TextEditingController(text: history));
    }
    if (_historyControllers.isEmpty) {
      _historyControllers.add(TextEditingController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Patient Information'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _saveChanges,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBasicInformation(),
                    SizedBox(height: 16),
                    _buildMedicalInformation(),
                    SizedBox(height: 16),
                    _buildAllergiesSection(),
                    SizedBox(height: 16),
                    _buildMedicalHistorySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInformation() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter name' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emergencyContactController,
              decoration: InputDecoration(
                labelText: 'Emergency Contact',
                prefixIcon: Icon(Icons.emergency),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInformation() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _bloodGroupController,
              decoration: InputDecoration(
                labelText: 'Blood Group',
                prefixIcon: Icon(Icons.bloodtype),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergiesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Allergies',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _allergyControllers.add(TextEditingController());
                    });
                  },
                ),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _allergyControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _allergyControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Allergy ${index + 1}',
                            prefixIcon: Icon(Icons.warning),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      if (_allergyControllers.length > 1)
                        IconButton(
                          icon: Icon(Icons.remove_circle),
                          color: Colors.red,
                          onPressed: () {
                            setState(() {
                              _allergyControllers[index].dispose();
                              _allergyControllers.removeAt(index);
                            });
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistorySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medical History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _historyControllers.add(TextEditingController());
                    });
                  },
                ),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _historyControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _historyControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Medical History ${index + 1}',
                            prefixIcon: Icon(Icons.history),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ),
                      if (_historyControllers.length > 1)
                        IconButton(
                          icon: Icon(Icons.remove_circle),
                          color: Colors.red,
                          onPressed: () {
                            setState(() {
                              _historyControllers[index].dispose();
                              _historyControllers.removeAt(index);
                            });
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw 'Not authenticated';

      // Check if user is a doctor
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.data()?['role'] != 'doctor') {
        throw 'Unauthorized access';
      }

      // Update patient data
      final updatedData = {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'bloodGroup': _bloodGroupController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim(),
        'allergies': _allergyControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList(),
        'medicalHistory': _historyControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': currentUser.uid,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patient.uid)
          .update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient information updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error updating patient information: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating patient information: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bloodGroupController.dispose();
    _emergencyContactController.dispose();
    _allergyControllers.forEach((controller) => controller.dispose());
    _historyControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }
}
