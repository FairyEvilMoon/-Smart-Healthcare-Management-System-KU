import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthcare_system_ku/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import '../../models/doctor_model.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  final DoctorModel doctor;

  const BookAppointmentScreen({Key? key, required this.doctor})
      : super(key: key);

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isLoading = false;

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('User not found');

      // Parse the time slot string into hours and minutes
      final timeComponents = _selectedTimeSlot!.split(':');
      final hours = int.parse(timeComponents[0]);
      final minutes = int.parse(timeComponents[1]);

      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        hours,
        minutes,
      );

      final appointment = AppointmentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: user.uid,
        doctorId: widget.doctor.uid,
        dateTime: appointmentDateTime,
        status: 'pending',
      );

      final appointmentService = AppointmentService();
      await appointmentService.bookAppointment(appointment);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment booked successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<String> _getAvailableTimeSlots() {
    if (_selectedDate == null) return [];

    final dayName = DateFormat('EEEE').format(_selectedDate!).toLowerCase();
    return widget.doctor.availability[dayName] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final availableTimeSlots = _getAvailableTimeSlots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Book Appointment'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dr. ${widget.doctor.name}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              widget.doctor.specialization,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 24),
            CalendarDatePicker(
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(Duration(days: 30)),
              onDateChanged: (date) {
                setState(() {
                  _selectedDate = date;
                  _selectedTimeSlot = null; // Reset time slot when date changes
                });
              },
            ),
            SizedBox(height: 24),
            if (_selectedDate != null) ...[
              Text(
                'Available Time Slots',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              if (availableTimeSlots.isEmpty)
                Text('No available slots for this day')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableTimeSlots
                      .map((timeSlot) => ChoiceChip(
                            label: Text(timeSlot),
                            selected: _selectedTimeSlot == timeSlot,
                            onSelected: (selected) {
                              setState(() {
                                _selectedTimeSlot = selected ? timeSlot : null;
                              });
                            },
                          ))
                      .toList(),
                ),
            ],
            Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _bookAppointment,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Book Appointment'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
