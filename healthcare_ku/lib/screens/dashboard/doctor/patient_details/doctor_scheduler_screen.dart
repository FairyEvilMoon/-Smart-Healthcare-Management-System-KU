import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:healthcare_ku/services/doctor_scheduler_service.dart';
import 'package:healthcare_ku/services/patient_service.dart';
import 'package:intl/intl.dart';
import '../../../../models/patient_model.dart';

class DoctorSchedulePatientScreen extends StatefulWidget {
  final String doctorId;
  final PatientModel? selectedPatient; // Optional: for pre-selected patient

  const DoctorSchedulePatientScreen({
    Key? key,
    required this.doctorId,
    this.selectedPatient,
  }) : super(key: key);

  @override
  _DoctorSchedulePatientScreenState createState() =>
      _DoctorSchedulePatientScreenState();
}

class _DoctorSchedulePatientScreenState
    extends State<DoctorSchedulePatientScreen> {
  final DoctorAppointmentService _appointmentService =
      DoctorAppointmentService();
  final PatientService _patientService = PatientService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  PatientModel? selectedPatient;
  DateTime? selectedDate;
  String? selectedTime;
  bool isLoading = false;
  List<PatientModel> filteredPatients = [];
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    selectedPatient = widget.selectedPatient;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() async {
    if (_searchController.text.length < 3) {
      setState(() {
        filteredPatients = [];
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    final results =
        await _patientService.searchPatients(_searchController.text);

    if (mounted) {
      setState(() {
        filteredPatients = results;
        isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedPatient != null
            ? 'Schedule for ${selectedPatient!.name}'
            : 'Schedule Patient'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (selectedPatient == null) _buildPatientSearch(),
            if (selectedPatient != null) ...[
              _buildPatientInfo(),
              SizedBox(height: 16),
              _buildDateSelection(),
              if (selectedDate != null) ...[
                SizedBox(height: 16),
                _buildTimeSelection(),
              ],
              if (selectedTime != null) ...[
                SizedBox(height: 16),
                _buildNotesField(),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildPatientSearch() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Patient',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter patient name or ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            filteredPatients = [];
                          });
                        },
                      )
                    : null,
              ),
            ),
            if (isSearching)
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (filteredPatients.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: filteredPatients.length,
                itemBuilder: (context, index) {
                  final patient = filteredPatients[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(patient.name[0]),
                      ),
                      title: Text(patient.name),
                      subtitle: Text(patient.email),
                      onTap: () {
                        setState(() {
                          selectedPatient = patient;
                          _searchController.clear();
                          filteredPatients = [];
                        });
                      },
                    ),
                  );
                },
              ),
          ],
        ),
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
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Text(selectedPatient!.name[0]),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPatient!.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(selectedPatient!.email),
                      if (selectedPatient!.phoneNumber != null)
                        Text(selectedPatient!.phoneNumber!),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      selectedPatient = null;
                      selectedDate = null;
                      selectedTime = null;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Date',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            CalendarDatePicker(
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(Duration(days: 90)),
              onDateChanged: (date) {
                setState(() {
                  selectedDate = date;
                  selectedTime = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var hour = 9; hour <= 17; hour++)
                  for (var minute in [0, 30])
                    _buildTimeChip(
                      TimeOfDay(hour: hour, minute: minute),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(TimeOfDay time) {
    final timeString = _formatTimeOfDay(time);
    final isSelected = selectedTime == timeString;

    return FilterChip(
      label: Text(timeString),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          selectedTime = selected ? timeString : null;
        });
      },
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
              'Appointment Notes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any notes for the appointment',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final canSchedule =
        selectedPatient != null && selectedDate != null && selectedTime != null;

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
        child: ElevatedButton(
          onPressed: canSchedule && !isLoading ? _scheduleAppointment : null,
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text('Schedule Appointment'),
        ),
      ),
    );
  }

  Future<void> _scheduleAppointment() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Parse the selected time
      final format = DateFormat('h:mm a');
      final parsedTime = format.parse(selectedTime!);

      // Create appointment DateTime
      final appointmentDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        parsedTime.hour,
        parsedTime.minute,
      );

      // Check for existing appointments
      final existingAppointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('dateTime', isEqualTo: Timestamp.fromDate(appointmentDateTime))
          .where('status', isEqualTo: 'scheduled')
          .get();

      if (existingAppointments.docs.isNotEmpty) {
        throw 'This time slot is already booked';
      }

      // Create the appointment
      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': selectedPatient!.uid,
        'doctorId': widget.doctorId,
        'dateTime': Timestamp.fromDate(appointmentDateTime),
        'status': 'scheduled',
        'purpose': 'Scheduled by doctor',
        'notes': _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment scheduled successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scheduling appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

// Add this helper method
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dateTime = DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
