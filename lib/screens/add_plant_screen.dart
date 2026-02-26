import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _nameController = TextEditingController();
  final _customDaysController = TextEditingController();
  final FocusNode _customFocusNode = FocusNode();
  bool _enableReminders = true;
  bool _isSaving = false;
  String _selectedFrequency = 'Every 2 days';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

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

  Future<void> _savePlantToFirebase() async {
    FocusScope.of(context).unfocus();
    final String plantName = _nameController.text.trim();

    if (plantName.isEmpty) {
      _showSnackBar('กรุณากรอกชื่อต้นไม้ด้วยครับ');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final String time24h =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      await FirebaseFirestore.instance.collection('plants').add({
        'name': plantName,
        'frequency': _selectedFrequency == 'Custom...'
            ? '${_customDaysController.text} days'
            : _selectedFrequency,
        'reminder_time': time24h,
        'is_enabled': _enableReminders,
        'created_at': Timestamp.now(),
        'userId': user.uid,
        'watered_dates': [],
      });

      if (mounted) {
        _nameController.clear();
        _customDaysController.clear();
        setState(() {
          _selectedFrequency = 'Every 2 days';
          _isSaving = false;
        });
        _showSnackBar('บันทึก "น้อง $plantName" เรียบร้อย! 🌱', isError: false);
      }
    } catch (e) {
      _showSnackBar('Error: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String time24h =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Add New Plant',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🛠️ ปรับขยับ UI ลงมาเพิ่มระยะห่างจากด้านบนเพื่อให้สมส่วน
            const SizedBox(height: 50),

            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_florist,
                  size: 60,
                  color: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 50), // ระยะห่างจากรูปถึงฟอร์ม

            const Text(
              'Plant Name:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'ตั้งชื่อให้น้องต้นไม้...',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedFrequency,
                  items: ['Daily', 'Every 2 days', 'Weekly', 'Custom...']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedFrequency = v!;
                      if (_selectedFrequency == 'Custom...')
                        _customFocusNode.requestFocus();
                    });
                  },
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
                  labelText: 'ระบุจำนวนวัน',
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
                'เลือกเวลาแจ้งเตือน',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: OutlinedButton.icon(
                onPressed: () => _showTimeRoller(context),
                // ⌚ เปลี่ยนกลับเป็นไอคอนนาฬิกาตามที่มึงสั่ง
                icon: const Icon(Icons.access_time, size: 18),
                label: Text(time24h),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                ),
              ),
            ),

            const SizedBox(height: 60), // เพิ่มระยะห่างก่อนปุ่มเซฟ

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePlantToFirebase,
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
                        'Save Plant to Cloud',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30), // ป้องกัน UI ชิดขอบล่างเกินไป
          ],
        ),
      ),
    );
  }
}
