import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/appointment_model.dart';
import '../../../services/appointment_service.dart';

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
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No upcoming appointments',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/book-appointment');
                    },
                    child: const Text('Book New Appointment'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.medical_services),
                  ),
                  title: Text(appointment.doctorName),
                  subtitle: Text(appointment.purpose),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('MMM d').format(appointment.dateTime),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('h:mm a').format(appointment.dateTime),
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () => _showAppointmentDetails(context, appointment),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAppointmentDetails(
      BuildContext context, AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appointment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor: ${appointment.doctorName}'),
            Text(
                'Date: ${DateFormat('MMMM d, y').format(appointment.dateTime)}'),
            Text('Time: ${DateFormat('h:mm a').format(appointment.dateTime)}'),
            Text('Purpose: ${appointment.purpose}'),
            if (appointment.specialization != null)
              Text('Specialization: ${appointment.specialization}'),
            if (appointment.notes != null) Text('Notes: ${appointment.notes}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          if (appointment.status == AppointmentStatus.scheduled)
            TextButton(
              onPressed: () async {
                await _appointmentService.cancelAppointment(appointment.id);
                Navigator.pop(context);
              },
              child: Text('Cancel Appointment'),
            ),
        ],
      ),
    );
  }
}
