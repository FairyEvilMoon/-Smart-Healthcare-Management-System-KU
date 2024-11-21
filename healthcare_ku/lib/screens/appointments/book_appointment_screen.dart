import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import '../../services/appointment_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String patientId;

  const BookAppointmentScreen({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final DoctorService _doctorService = DoctorService();
  final AppointmentService _appointmentService = AppointmentService();
  final TextEditingController _purposeController = TextEditingController();

  String? selectedSpecialization;
  DoctorModel? selectedDoctor;
  DateTime? selectedDate;
  String? selectedTime;
  bool isLoading = false;

  final List<String> specializations = [
    'Cardiology',
    'Dermatology',
    'General Medicine',
    'Neurology',
    'Pediatrics',
    'Psychiatry',
    // Add more specializations as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Specialization Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Specialization',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedSpecialization,
                      decoration: const InputDecoration(
                        hintText: 'Choose specialization',
                        border: OutlineInputBorder(),
                      ),
                      items: specializations.map((String specialization) {
                        return DropdownMenuItem(
                          value: specialization,
                          child: Text(specialization),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedSpecialization = newValue;
                          selectedDoctor = null;
                          selectedDate = null;
                          selectedTime = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Doctor Selection
            if (selectedSpecialization != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Doctor',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<DoctorModel>>(
                        stream: _doctorService.getDoctorsBySpecialization(
                          selectedSpecialization!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          final doctors = snapshot.data ?? [];

                          if (doctors.isEmpty) {
                            return const Text(
                                'No doctors available for this specialization');
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: doctors.length,
                            itemBuilder: (context, index) {
                              final doctor = doctors[index];
                              return RadioListTile<DoctorModel>(
                                title: Text(doctor.name),
                                subtitle: Text(doctor.specialization ?? ''),
                                value: doctor,
                                groupValue: selectedDoctor,
                                onChanged: (DoctorModel? value) {
                                  setState(() {
                                    selectedDoctor = value;
                                    selectedDate = null;
                                    selectedTime = null;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Date Selection
            if (selectedDoctor != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Date',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                              selectedTime = null;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          selectedDate == null
                              ? 'Choose Date'
                              : DateFormat('EEEE, MMMM d, y')
                                  .format(selectedDate!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Time Selection
            if (selectedDate != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Time',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<String>>(
                        stream: _doctorService.getAvailableTimeSlots(
                          selectedDoctor!.uid,
                          selectedDate!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          final timeSlots = snapshot.data ?? [];

                          if (timeSlots.isEmpty) {
                            return const Text(
                                'No available time slots for this date');
                          }

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: timeSlots.map((String time) {
                              return ChoiceChip(
                                label: Text(time),
                                selected: selectedTime == time,
                                onSelected: (bool selected) {
                                  setState(() {
                                    selectedTime = selected ? time : null;
                                  });
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Purpose of Visit
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purpose of Visit',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _purposeController,
                      decoration: const InputDecoration(
                        hintText: 'Enter the reason for your appointment',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Book Button
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : _canBook()
                      ? _bookAppointment
                      : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Book Appointment'),
            ),
          ],
        ),
      ),
    );
  }

  bool _canBook() {
    return selectedDoctor != null &&
        selectedDate != null &&
        selectedTime != null &&
        _purposeController.text.isNotEmpty;
  }

  Future<void> _bookAppointment() async {
    if (!_canBook()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'No authenticated user found';
      }

      print('Booking appointment for user: ${user.uid}');

      final dateTimeString =
          '${DateFormat('yyyy-MM-dd').format(selectedDate!)} $selectedTime';
      final appointmentDateTime =
          DateFormat('yyyy-MM-dd HH:mm').parse(dateTimeString);

      await _appointmentService.createAppointment(
        patientId: user.uid, // Use the current user's ID
        doctorId: selectedDoctor!.uid,
        doctorName: selectedDoctor!.name,
        purpose: _purposeController.text.trim(),
        dateTime: appointmentDateTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error in _bookAppointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }
}
