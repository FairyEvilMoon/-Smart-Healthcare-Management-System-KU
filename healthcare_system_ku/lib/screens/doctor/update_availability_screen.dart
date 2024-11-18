// lib/screens/doctor/update_availability_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthcare_system_ku/providers/auth_provider.dart';
import 'package:healthcare_system_ku/utilities/capitalize.dart';
import '../../services/availability_service.dart';

class UpdateAvailabilityScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<UpdateAvailabilityScreen> createState() =>
      _UpdateAvailabilityScreenState();
}

class _UpdateAvailabilityScreenState
    extends ConsumerState<UpdateAvailabilityScreen> {
  final Map<String, List<String>> _availability = {
    'monday': [],
    'tuesday': [],
    'wednesday': [],
    'thursday': [],
    'friday': [],
    'saturday': [],
    'sunday': [],
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentAvailability();
  }

  Future<void> _loadCurrentAvailability() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final doctorDoc = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(user.uid)
        .get();

    if (doctorDoc.exists) {
      setState(() {
        _availability.addAll(
          Map<String, List<String>>.from(
              doctorDoc.data()?['availability'] ?? {}),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Availability'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                ..._availability.entries.map((entry) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key.capitalize(),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              TextButton.icon(
                                onPressed: () => _showTimeSlotDialog(entry.key),
                                icon: Icon(Icons.add),
                                label: Text('Add Slot'),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          if (entry.value.isEmpty)
                            Text('No time slots added')
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: entry.value.map((timeSlot) {
                                return Chip(
                                  label: Text(timeSlot),
                                  onDeleted: () {
                                    setState(() {
                                      _availability[entry.key]!
                                          .remove(timeSlot);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAvailability,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Save Availability'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _saveAvailability() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw Exception('User not found');

      final availabilityService = AvailabilityService();
      await availabilityService.updateDoctorAvailability(
        user.uid,
        _availability,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Availability updated successfully')),
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

  Future<void> _showTimeSlotDialog(String day) async {
    TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
    );

    if (startTime != null) {
      setState(() {
        final formattedTime =
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
        if (!_availability[day]!.contains(formattedTime)) {
          _availability[day]!.add(formattedTime);
          _availability[day]!.sort();
        }
      });
    }
  }
}
