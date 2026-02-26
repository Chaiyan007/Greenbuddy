import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPlantScreen extends StatefulWidget {
  final String plantId;
  final Map<String, dynamic> currentData;

  const EditPlantScreen({
    super.key,
    required this.plantId,
    required this.currentData,
  });

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  late TextEditingController _nameController;
  late TextEditingController _customDaysController;
  final FocusNode _customFocusNode = FocusNode();
  late String _selectedFrequency;
  late TimeOfDay _selectedTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentData['name']);
    String freq = widget.currentData['frequency'] ?? 'Daily';

    if (freq.contains('days') &&
        !['Daily', 'Every 2 days', 'Weekly'].contains(freq)) {
      _selectedFrequency = 'Custom...';
      _customDaysController = TextEditingController(text: freq.split(' ')[0]);
    } else {
      _selectedFrequency = ['Daily', 'Every 2 days', 'Weekly'].contains(freq)
          ? freq
          : 'Daily';
      _customDaysController = TextEditingController();
    }

    final timeParts = (widget.currentData['reminder_time'] ?? "08:00").split(
      ':',
    );
    _selectedTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
  }

  void _showTimeRoller(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime(
                  2026,
                  1,
                  1,
                  _selectedTime.hour,
                  _selectedTime.minute,
                ),
                onDateTimeChanged: (newTime) {
                  setState(
                    () => _selectedTime = TimeOfDay.fromDateTime(newTime),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePlant() async {
    setState(() => _isSaving = true);
    try {
      final String time24h =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      await FirebaseFirestore.instance
          .collection('plants')
          .doc(widget.plantId)
          .update({
            'name': _nameController.text.trim(),
            'frequency': _selectedFrequency == 'Custom...'
                ? '${_customDaysController.text} days'
                : _selectedFrequency,
            'reminder_time': time24h,
          });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Plant Info',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40), // 🛠️ ปรับสัดส่วนให้สมดุลกับหน้า Add

            const Text(
              'Plant Name:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Frequency:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              items: [
                'Daily',
                'Every 2 days',
                'Weekly',
                'Custom...',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedFrequency = v!;
                  if (_selectedFrequency == 'Custom...')
                    _customFocusNode.requestFocus();
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            if (_selectedFrequency == 'Custom...') ...[
              const SizedBox(height: 15),
              TextField(
                controller: _customDaysController,
                focusNode: _customFocusNode,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'จำนวนวัน',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_calendar),
                ),
              ),
            ],

            const SizedBox(height: 30),

            const Text(
              'Reminder Time:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'ปรับเวลาแจ้งเตือน',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: OutlinedButton.icon(
                onPressed: () => _showTimeRoller(context),
                // ⌚ เปลี่ยนเป็นไอคอนนาฬิกาตามมึงสั่ง
                icon: const Icon(Icons.access_time, size: 18),
                label: Text(_selectedTime.format(context)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                ),
              ),
            ),

            const SizedBox(height: 60),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updatePlant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update Plant Info',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
