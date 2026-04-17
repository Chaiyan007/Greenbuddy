import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'my_plants_screen.dart';
import 'calendar_screen.dart';
import 'add_plant_screen.dart';


class MainHub extends StatefulWidget {
  const MainHub({super.key});


  @override
  State<MainHub> createState() => _MainHubState();
}


class _MainHubState extends State<MainHub> {
  int _selectedIndex = 0;

  // 🛠️ ลิสต์หน้าจอที่จะแสดง
  final List<Widget> _screens = [
    const MyPlantsScreen(),
    const CalendarScreen(),
    const AddPlantScreen(),
  ];

  // 🧠 ฟังก์ชันช่วยเช็คว่าวันนี้ต้องรดน้ำต้นไม้ต้นนี้ไหม
  bool _checkIfNeedsWatering(DateTime selected, Timestamp? createdTimestamp, String freq) {
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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      // IndexedStack ช่วยให้สลับหน้าแล้วข้อมูลไม่หาย
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Plants',
          ),
          
          // 📅 ปุ่ม Calendar พร้อมเลขแจ้งเตือนสีแดง
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('plants')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                int pendingCount = 0;

                if (snapshot.hasData) {
                  final now = DateTime.now();
                  final todayStr = DateFormat('yyyy-MM-dd').format(now);

                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    
                    // เช็คว่าต้องรดวันนี้ไหม
                    bool needsToday = _checkIfNeedsWatering(
                      now, 
                      data['created_at'], 
                      data['frequency'] ?? 'Daily'
                    );

                    // เช็คว่ารดไปหรือยัง
                    List wateredDates = data['watered_dates'] ?? [];
                    bool isWatered = wateredDates.contains(todayStr);

                    // ถ้าต้องรดแต่ยังไม่ได้รด -> นับเป็นงานค้าง
                    if (needsToday && !isWatered) {
                      pendingCount++;
                    }
                  }
                }

                return Badge(
                  label: Text(pendingCount.toString()),
                  isLabelVisible: pendingCount > 0, // โชว์เลขเมื่อมีงานค้างมากกว่า 0
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.calendar_month_outlined),
                );
              },
            ),
            activeIcon: const Icon(Icons.calendar_month),
            label: 'Calendar',
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Add',
          ),
        ],
      ),
    );
  }
}



