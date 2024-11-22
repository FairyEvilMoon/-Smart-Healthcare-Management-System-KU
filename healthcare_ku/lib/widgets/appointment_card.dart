// lib/widgets/appointment_card.dart

import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import 'package:intl/intl.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final Function()? onCancelTap;

  const AppointmentCard({
    Key? key,
    required this.appointment,
    this.onCancelTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, y').format(appointment.dateTime),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${DateFormat('h:mm a').format(appointment.dateTime)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Doctor: ${appointment.doctorName ?? "Not assigned"}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (appointment.specialization != null) ...[
              const SizedBox(height: 4),
              Text(
                appointment.specialization!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Purpose: ${appointment.purpose}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (appointment.status == AppointmentStatus.scheduled) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancelTap,
                    child: const Text('Cancel Appointment'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    switch (appointment.status) {
      case AppointmentStatus.scheduled:
        chipColor = Colors.blue;
        break;
      case AppointmentStatus.completed:
        chipColor = Colors.green;
        break;
      case AppointmentStatus.cancelled:
        chipColor = Colors.red;
        break;
      case AppointmentStatus.noShow:
        chipColor = Colors.orange;
        break;
    }

    return Chip(
      label: Text(
        appointment.status.toString().split('.').last,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: chipColor,
    );
  }
}
