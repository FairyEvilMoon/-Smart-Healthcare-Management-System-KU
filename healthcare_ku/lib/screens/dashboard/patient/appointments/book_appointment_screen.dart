import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/doctor_model.dart';
import '../../../../models/availability_slot_model.dart';
import '../../../../services/doctor_service.dart';
import '../../../../services/appointment_service.dart';
import '../../../../services/availability_service.dart';

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
  final AvailabilityService _availabilityService = AvailabilityService();
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
  ];

  // Add a method to generate available time slots based on availability
  List<String> _generateTimeSlots(
      List<AvailabilitySlotModel> availabilitySlots) {
    if (selectedDate == null) return [];

    final slots = _availabilityService.generateTimeSlots(
      selectedDate!,
      availabilitySlots,
    );

    return slots
        .map((dateTime) => DateFormat('HH:mm').format(dateTime))
        .toList();
  }

  // Modified time slot selection widget
  Widget _buildTimeSlotSelection() {
    return StreamBuilder<List<AvailabilitySlotModel>>(
      stream: _availabilityService.getDoctorAvailability(selectedDoctor!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final availabilitySlots = snapshot.data ?? [];
        if (availabilitySlots.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.schedule, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'No availability set for this doctor',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check back later or select another doctor',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final timeSlots = _generateTimeSlots(availabilitySlots);
        if (timeSlots.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.event_busy, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'No available slots for selected date',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please select a different date',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Time Slots',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: timeSlots.map((time) {
                    return FilterChip(
                      label: Text(time),
                      selected: selectedTime == time,
                      onSelected: (bool selected) {
                        setState(() {
                          selectedTime = selected ? time : null;
                        });
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor:
                          Theme.of(context).primaryColor.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

            // Doctor Selection (Keep your existing doctor selection widget)
            if (selectedSpecialization != null) ...[
              _buildDoctorSelection(),
              const SizedBox(height: 16),
            ],

            // Date Selection
            if (selectedDoctor != null) ...[
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
                      const SizedBox(height: 16),
                      CalendarDatePicker(
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        onDateChanged: (DateTime date) {
                          setState(() {
                            selectedDate = date;
                            selectedTime = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Time Selection
            if (selectedDate != null) ...[
              _buildTimeSlotSelection(),
              const SizedBox(height: 16),
            ],

            // Purpose of Visit
            if (selectedTime != null) ...[
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
            ],

            // Book Button
            if (_canBook())
              ElevatedButton(
                onPressed: isLoading ? null : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Book Appointment'),
              ),
          ],
        ),
      ),
    );
  }

  // Update the _bookAppointment method to work with the new availability system
  Future<void> _bookAppointment() async {
    if (!_canBook()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'No authenticated user found';

      final dateTimeString =
          '${DateFormat('yyyy-MM-dd').format(selectedDate!)} $selectedTime:00';
      final appointmentDateTime =
          DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTimeString);

      // Create the appointment
      await _appointmentService.createAppointment(
        patientId: widget.patientId,
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

  bool _canBook() {
    return selectedDoctor != null &&
        selectedDate != null &&
        selectedTime != null &&
        _purposeController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  Widget _buildDoctorSelection() {
    return Card(
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
                  return Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Error loading doctors: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Loading doctors...'),
                      ],
                    ),
                  );
                }

                final doctors = snapshot.data ?? [];

                if (doctors.isEmpty) {
                  return Column(
                    children: [
                      const Icon(Icons.person_off,
                          color: Colors.grey, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'No doctors available for $selectedSpecialization',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            selectedSpecialization = null;
                          });
                        },
                        child: const Text('Choose Another Specialization'),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text(
                            doctor.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text('Dr. ${doctor.name}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (doctor.specialization != null)
                              Text(doctor.specialization!),
                            if (doctor.licenseNumber != null)
                              Text(
                                'License: ${doctor.licenseNumber}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                        trailing: Radio<DoctorModel>(
                          value: doctor,
                          groupValue: selectedDoctor,
                          onChanged: (DoctorModel? value) {
                            setState(() {
                              selectedDoctor = value;
                              selectedDate = null;
                              selectedTime = null;
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            selectedDoctor = doctor;
                            selectedDate = null;
                            selectedTime = null;
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
