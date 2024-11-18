import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import '../../services/firebase_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _firebaseService = FirebaseService();
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String? _selectedDoctor;
  bool _isLoading = false;

  List<String> _timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null ||
        _selectedTimeSlot == null ||
        _selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Convert selected time slot to DateTime
    final timeComponents = _selectedTimeSlot!.split(':');
    final hour = int.parse(timeComponents[0]);
    final minute = int.parse(timeComponents[1].split(' ')[0]);
    final isPM = _selectedTimeSlot!.endsWith('PM');

    final appointmentDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      isPM ? hour + 12 : hour,
      minute,
    );

    final appointment = AppointmentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      doctorId: _selectedDoctor!,
      patientId: 'current-user-id', // Replace with actual patient ID
      dateTime: appointmentDateTime,
      status: 'pending',
    );

    final success = await _firebaseService.createAppointment(appointment);

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment booked successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book appointment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Appointment'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Doctor',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 16),
                    // Add doctor selection dropdown here
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Date & Time',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text(_selectedDate == null
                          ? 'Select Date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Available Time Slots',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _timeSlots.map((slot) {
                        return ChoiceChip(
                          label: Text(slot),
                          selected: _selectedTimeSlot == slot,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTimeSlot = selected ? slot : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _bookAppointment,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Book Appointment'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/screens/appointments/appointment_confirmation_screen.dart
class AppointmentConfirmationScreen extends StatelessWidget {
  final AppointmentModel appointment;

  AppointmentConfirmationScreen({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appointment Confirmed'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 24),
            Text(
              'Appointment Confirmed!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Date',
                        '${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year}'),
                    _buildInfoRow('Time',
                        '${appointment.dateTime.hour}:${appointment.dateTime.minute.toString().padLeft(2, '0')}'),
                    _buildInfoRow('Status', appointment.status),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(
                context,
                ModalRoute.withName('/dashboard'),
              ),
              child: Text('Return to Dashboard'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
