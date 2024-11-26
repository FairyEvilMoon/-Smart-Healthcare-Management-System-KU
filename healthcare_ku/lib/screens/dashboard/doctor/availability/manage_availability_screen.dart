import 'package:flutter/material.dart';
import 'package:healthcare_ku/models/availability_slot_model.dart';
import 'package:healthcare_ku/services/availability_service.dart';
import 'package:intl/intl.dart';

class ManageAvailabilityScreen extends StatefulWidget {
  final String doctorId;

  const ManageAvailabilityScreen({Key? key, required this.doctorId})
      : super(key: key);

  @override
  _ManageAvailabilityScreenState createState() =>
      _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  final AvailabilityService _availabilityService = AvailabilityService();
  bool _isRecurring = false;
  List<String> _selectedDays = [];
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 17, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Availability'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Availability List
            StreamBuilder<List<AvailabilitySlotModel>>(
              stream:
                  _availabilityService.getDoctorAvailability(widget.doctorId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                final slots = snapshot.data ?? [];
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    return Card(
                      child: ListTile(
                        title: Text(slot.isRecurring
                            ? 'Recurring: ${slot.recurringDays.join(", ")}'
                            : 'One-time slot'),
                        subtitle: Text(
                            '${_formatDateTime(slot.startTime)} - ${_formatDateTime(slot.endTime)}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteSlot(slot.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            SizedBox(height: 20),

            // Add New Availability Form
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Availability',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SwitchListTile(
                      title: Text('Recurring Schedule'),
                      value: _isRecurring,
                      onChanged: (value) {
                        setState(() {
                          _isRecurring = value;
                        });
                      },
                    ),
                    if (_isRecurring) ...[
                      Wrap(
                        spacing: 8,
                        children: [
                          'Monday',
                          'Tuesday',
                          'Wednesday',
                          'Thursday',
                          'Friday',
                          'Saturday',
                          'Sunday'
                        ].map((day) {
                          return FilterChip(
                            label: Text(day),
                            selected: _selectedDays.contains(day),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedDays.add(day);
                                } else {
                                  _selectedDays.remove(day);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    ListTile(
                      title: Text('Start Time'),
                      trailing: Text(_formatTimeOfDay(_startTime)),
                      onTap: () => _selectTime(context, true),
                    ),
                    ListTile(
                      title: Text('End Time'),
                      trailing: Text(_formatTimeOfDay(_endTime)),
                      onTap: () => _selectTime(context, false),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addAvailabilitySlot,
                      child: Text('Add Availability'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime);
  }

  Future<void> _addAvailabilitySlot() async {
    if (_isRecurring && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _endTime.hour,
      _endTime.minute,
    );

    final slot = AvailabilitySlotModel(
      id: '', // Will be set by Firestore
      startTime: startDateTime,
      endTime: endDateTime,
      isRecurring: _isRecurring,
      recurringDays: _selectedDays,
    );

    try {
      await _availabilityService.addAvailabilitySlot(widget.doctorId, slot);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Availability added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding availability: $e')),
      );
    }
  }

  Future<void> _deleteSlot(String slotId) async {
    try {
      await _availabilityService.deleteAvailabilitySlot(
          widget.doctorId, slotId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Availability removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing availability: $e')),
      );
    }
  }
}
