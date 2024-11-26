import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/appointment_model.dart';
import '../../../../services/appointment_service.dart';

class UpcomingAppointmentsScreen extends StatelessWidget {
  final String patientId;
  final AppointmentService _appointmentService = AppointmentService();

  UpcomingAppointmentsScreen({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Appointments'),
      ),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: _appointmentService.getUpcomingAppointments(patientId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No upcoming appointments',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/book-appointment',
                        arguments: patientId,
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Book New Appointment'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _showAppointmentDetails(context, appointment),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              child: const Icon(Icons.medical_services),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dr. ${appointment.doctorName}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (appointment.specialization != null)
                                    Text(
                                      appointment.specialization!,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.event,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('EEEE, MMMM d, y')
                                  .format(appointment.dateTime),
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('h:mm a').format(appointment.dateTime),
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Purpose: ${appointment.purpose}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/book-appointment',
            arguments: patientId,
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Book Appointment'),
      ),
    );
  }

  void _showAppointmentDetails(
      BuildContext context, AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: Text('Dr. ${appointment.doctorName}'),
                subtitle: appointment.specialization != null
                    ? Text(appointment.specialization!)
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.event),
                title: Text(
                  DateFormat('EEEE, MMMM d, y').format(appointment.dateTime),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(
                  DateFormat('h:mm a').format(appointment.dateTime),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.note),
                title: const Text('Purpose'),
                subtitle: Text(appointment.purpose),
              ),
              if (appointment.notes != null)
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Additional Notes'),
                  subtitle: Text(appointment.notes!),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (appointment.status == AppointmentStatus.scheduled)
            TextButton(
              onPressed: () async {
                try {
                  await _appointmentService.cancelAppointment(appointment.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Appointment cancelled successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error cancelling appointment: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Cancel Appointment'),
            ),
        ],
      ),
    );
  }
}
