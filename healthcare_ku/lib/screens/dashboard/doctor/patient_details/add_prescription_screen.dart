import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthcare_ku/models/prescription_model.dart';
import 'package:intl/intl.dart';

class AddPrescriptionScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String? appointmentId;
  final PrescriptionModel? existingPrescription;

  const AddPrescriptionScreen({
    Key? key,
    required this.patientId,
    required this.patientName,
    this.appointmentId,
    this.existingPrescription,
  }) : super(key: key);

  @override
  _AddPrescriptionScreenState createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime _endDate = DateTime.now().add(Duration(days: 7));
  List<MedicationFormItem> _medications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingPrescription != null) {
      _loadExistingPrescription();
    } else {
      _medications.add(MedicationFormItem());
    }
  }

  void _loadExistingPrescription() {
    setState(() {
      _notesController.text = widget.existingPrescription!.notes;
      _endDate = widget.existingPrescription!.endDate;
      _medications = widget.existingPrescription!.medications
          .map((med) => MedicationFormItem(
                nameController: TextEditingController(text: med.name),
                dosageController: TextEditingController(text: med.dosage),
                frequencyController: TextEditingController(text: med.frequency),
                instructionsController:
                    TextEditingController(text: med.instructions),
              ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPrescription != null
            ? 'Edit Prescription'
            : 'Add Prescription'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildPatientInfo(),
            SizedBox(height: 16),
            _buildMedicationsList(),
            SizedBox(height: 16),
            _buildEndDatePicker(),
            SizedBox(height: 16),
            _buildNotesField(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedication,
        child: Icon(Icons.add),
        tooltip: 'Add Medication',
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Name: ${widget.patientName}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              'Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medications',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        ..._medications.asMap().entries.map((entry) {
          final index = entry.key;
          final medication = entry.value;
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Medication ${index + 1}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (_medications.length > 1)
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeMedication(index),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: medication.nameController,
                    decoration: InputDecoration(
                      labelText: 'Medication Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter medication name'
                        : null,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: medication.dosageController,
                          decoration: InputDecoration(
                            labelText: 'Dosage',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Please enter dosage'
                              : null,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: medication.frequencyController,
                          decoration: InputDecoration(
                            labelText: 'Frequency',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Please enter frequency'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: medication.instructionsController,
                    decoration: InputDecoration(
                      labelText: 'Instructions',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter instructions'
                        : null,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEndDatePicker() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'End Date',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: _selectEndDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                    Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add any additional notes',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePrescription,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.existingPrescription != null
                        ? 'Update Prescription'
                        : 'Save Prescription'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addMedication() {
    setState(() {
      _medications.add(MedicationFormItem());
    });
  }

  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final medications = _medications
          .map((med) => Medication(
                name: med.nameController.text,
                dosage: med.dosageController.text,
                frequency: med.frequencyController.text,
                instructions: med.instructionsController.text,
              ))
          .toList();

      final prescriptionData = {
        'patientId': widget.patientId,
        'doctorId': FirebaseAuth.instance.currentUser!.uid,
        'prescriptionDate': Timestamp.now(),
        'medications': medications.map((med) => med.toMap()).toList(),
        'endDate': Timestamp.fromDate(_endDate),
        'status': 'Active',
        'notes': _notesController.text,
        'appointmentId': widget.appointmentId,
      };

      if (widget.existingPrescription != null) {
        await FirebaseFirestore.instance
            .collection('prescriptions')
            .doc(widget.existingPrescription!.id)
            .update(prescriptionData);
      } else {
        final docRef = await FirebaseFirestore.instance
            .collection('prescriptions')
            .add(prescriptionData);
        prescriptionData['id'] = docRef.id;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingPrescription != null
                ? 'Prescription updated successfully'
                : 'Prescription saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving prescription: $e'),
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
    _notesController.dispose();
    for (var med in _medications) {
      med.dispose();
    }
    super.dispose();
  }
}

class MedicationFormItem {
  final TextEditingController nameController;
  final TextEditingController dosageController;
  final TextEditingController frequencyController;
  final TextEditingController instructionsController;

  MedicationFormItem({
    TextEditingController? nameController,
    TextEditingController? dosageController,
    TextEditingController? frequencyController,
    TextEditingController? instructionsController,
  })  : this.nameController = nameController ?? TextEditingController(),
        this.dosageController = dosageController ?? TextEditingController(),
        this.frequencyController =
            frequencyController ?? TextEditingController(),
        this.instructionsController =
            instructionsController ?? TextEditingController();

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    instructionsController.dispose();
  }
}
