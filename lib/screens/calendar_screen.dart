import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  // 🧠 ฟังก์ชันคำนวณว่าต้องรดน้ำไหม
  bool _needsWatering(
    DateTime selected,
    Timestamp? createdTimestamp,
    String freq,
  ) {
    if (createdTimestamp == null) return false;

    DateTime start = DateTime(
      createdTimestamp.toDate().year,
      createdTimestamp.toDate().month,
      createdTimestamp.toDate().day,
    );
    DateTime target = DateTime(selected.year, selected.month, selected.day);

    int diff = target.difference(start).inDays;

    if (diff < 0) return false;
    if (freq == 'Daily') return true;
    if (freq == 'Every 2 days') return diff % 2 == 0;
    if (freq == 'Weekly') return diff % 7 == 0;

    if (freq.contains('days')) {
      try {
        int days = int.parse(freq.split(' ')[0]);
        return diff % days == 0;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  // 💧 ฟังก์ชันบันทึกการรดน้ำลง Firestore
  Future<void> _waterPlant(
    String docId,
    String plantName,
    String dateStr,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('plants').doc(docId).update({
        'watered_dates': FieldValue.arrayUnion([dateStr]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('รดน้ำให้น้อง "$plantName" เรียบร้อย! 💦'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // 🛠️ แปลงวันที่เลือกให้เป็นฟอร์แมตเพื่อเช็คสถานะ
    final String selectedDateStr = DateFormat(
      'yyyy-MM-dd',
    ).format(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Row(
          children: [
            Text(
              'Watering Schedule ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Icon(
              Icons.calendar_month,
              color: Colors.green,
            ), // เปลี่ยนจากอีโมจิเป็นไอคอนที่ดูโปรขึ้น
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // 📅 แถบเลือกวันที่
          CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            onDateChanged: (date) => setState(() => _selectedDate = date),
          ),

          const Divider(thickness: 1, color: Colors.grey),

          // 🌿 แสดงรายการต้นไม้
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('plants')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('เกิดข้อผิดพลาด'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'ไม่มีข้อมูลต้นไม้',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final todo = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return _needsWatering(
                    _selectedDate,
                    data['created_at'],
                    data['frequency'] ?? 'Daily',
                  );
                }).toList();

                if (todo.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 60,
                          color: Colors.green,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'วันนี้ไม่มีรายการรดน้ำ 🎉',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: todo.length,
                  itemBuilder: (context, index) {
                    final doc = todo[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;

                    // 🔍 เช็คว่ารดน้ำไปหรือยังในวันนี้
                    final List<dynamic> wateredDates =
                        data['watered_dates'] ?? [];
                    final bool isWatered = wateredDates.contains(
                      selectedDateStr,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      // 🎨 เปลี่ยนพื้นหลังการ์ดให้เป็นสีเทาอ่อนๆ ถ้ารดน้ำแล้ว
                      color: isWatered ? Colors.grey[50] : Colors.blue[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: isWatered
                              ? Colors.grey.shade300
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      elevation: 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            // 🎨 ไอคอนด้านหน้าเปลี่ยนเป็นเทาถ้ารดแล้ว
                            color: isWatered ? Colors.grey[400] : Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isWatered ? Icons.check : Icons.water_drop,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          data['name'] ?? 'Unknown Plant',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isWatered ? Colors.grey[700] : Colors.black,
                          ),
                        ),
                        subtitle: Text('เวลา: ${data['reminder_time']}'),
                        trailing: ElevatedButton(
                          // 🧠 ฟังก์ชันเช็คการกดปุ่ม
                          onPressed: () {
                            if (isWatered) {
                              // แจ้งเตือนถ้ารดไปแล้ว
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'วันนี้คุณได้รดน้ำไปแล้วครับ! 💦',
                                  ),
                                  backgroundColor:
                                      Colors.orange, // สีส้มเตือนซอฟต์ๆ
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else {
                              // บันทึกการรดน้ำถ้ายังไม่ได้รด
                              _waterPlant(
                                docId,
                                data['name'] ?? 'ต้นไม้',
                                selectedDateStr,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            // 🎨 ปุ่มยุบตัว เปลี่ยนเป็นสีเทา
                            backgroundColor: isWatered
                                ? Colors.grey[200]
                                : Colors.blue,
                            foregroundColor: isWatered
                                ? Colors.grey[600]
                                : Colors.white,
                            elevation: isWatered
                                ? 0
                                : 3, // เอาเงาออกให้ดูจมลงไป
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isWatered
                                    ? Colors.grey.shade300
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(isWatered ? 'รดน้ำแล้ว ✓' : 'รดน้ำ'),
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
}
