import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthcare_system_ku/models/doctor_model.dart';
import 'package:healthcare_system_ku/screens/patient/book_appointment_screen.dart';
import 'package:healthcare_system_ku/utilities/capitalize.dart';

class DoctorListScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends ConsumerState<DoctorListScreen> {
  String _searchQuery = '';
  String? _selectedSpecialization;
  List<String> _specializations = [];

  @override
  void initState() {
    super.initState();
    _loadSpecializations();
  }

  Future<void> _loadSpecializations() async {
    final specs = await DoctorService().getAvailableSpecializations();
    setState(() {
      _specializations = specs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find a Doctor'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search doctors...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Specialization',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: _selectedSpecialization,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text('All Specializations'),
                    ),
                    ..._specializations.map(
                      (spec) => DropdownMenuItem(
                        value: spec,
                        child: Text(spec),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSpecialization = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DoctorModel>>(
              stream: DoctorService().getDoctors(
                searchQuery: _searchQuery,
                specialization: _selectedSpecialization,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading doctors'));
                }

                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final doctors = snapshot.data!;
                if (doctors.isEmpty) {
                  return Center(child: Text('No doctors found'));
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
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
                                  backgroundImage: doctor.profileImageUrl !=
                                          null
                                      ? NetworkImage(doctor.profileImageUrl!)
                                      : null,
                                  child: doctor.profileImageUrl == null
                                      ? Text(doctor.name[0])
                                      : null,
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dr. ${doctor.name}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      Text(
                                        doctor.specialization,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: doctor.qualifications
                                  .map((qual) => Chip(label: Text(qual)))
                                  .toList(),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: Icon(Icons.info_outline),
                                    label: Text('View Profile'),
                                    onPressed: () => _showDoctorProfile(doctor),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.calendar_today),
                                    label: Text('Book'),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BookAppointmentScreen(
                                          doctor: doctor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDoctorProfile(DoctorModel doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: doctor.profileImageUrl != null
                      ? NetworkImage(doctor.profileImageUrl!)
                      : null,
                  child: doctor.profileImageUrl == null
                      ? Text(
                          doctor.name[0],
                          style: TextStyle(fontSize: 32),
                        )
                      : null,
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'Dr. ${doctor.name}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Center(
                child: Text(
                  doctor.specialization,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Qualifications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: doctor.qualifications
                    .map((qual) => Chip(label: Text(qual)))
                    .toList(),
              ),
              SizedBox(height: 24),
              Text(
                'Available Time Slots',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              _buildAvailabilityView(doctor.availability),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookAppointmentScreen(
                        doctor: doctor,
                      ),
                    ),
                  );
                },
                child: Text('Book Appointment'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityView(Map<String, List<String>> availability) {
    return Column(
      children: availability.entries.map((entry) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  entry.key.capitalize(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.value.isEmpty
                      ? [Text('Not available')]
                      : entry.value
                          .map((time) => Chip(
                                label: Text(time),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
