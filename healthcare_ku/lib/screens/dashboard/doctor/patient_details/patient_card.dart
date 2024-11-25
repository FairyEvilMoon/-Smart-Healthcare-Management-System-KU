import 'package:flutter/material.dart';
import 'package:healthcare_ku/models/patient_model.dart';

class PatientCard extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onTap;
  final VoidCallback? onAddRecord;

  const PatientCard({
    Key? key,
    required this.patient,
    required this.onTap,
    this.onAddRecord,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
                child: patient.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          patient.profileImageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildInitials(),
                        ),
                      )
                    : _buildInitials(),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            patient.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(patient.status)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            patient.status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(patient.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      patient.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.bloodtype, size: 16, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          patient.bloodGroup.isNotEmpty
                              ? patient.bloodGroup
                              : 'Not specified',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.phone, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          patient.phoneNumber ?? 'No phone',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    if (patient.allergies.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: patient.allergies
                            .take(2)
                            .map(
                              (allergy) => Chip(
                                label: Text(
                                  allergy,
                                  style: TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.red[100],
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitials() {
    return Text(
      patient.name.split(' ').take(2).map((e) => e[0]).join('').toUpperCase(),
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
