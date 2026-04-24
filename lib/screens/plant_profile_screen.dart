import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'edit_plant_screen.dart'; // 🛠️ อย่าลืมสร้างไฟล์นี้ตามที่กูให้ไว้รอบก่อนนะเพื่อน!

class PlantProfileScreen extends StatefulWidget {
  final String plantId;
  final String plantName;
  final Map<String, dynamic> plantData;

  const PlantProfileScreen({
    super.key,
    required this.plantId,
    required this.plantName,
    required this.plantData,
  });

  @override
  State<PlantProfileScreen> createState() => _PlantProfileScreenState();
}

class _PlantProfileScreenState extends State<PlantProfileScreen> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // 📸 ฟังก์ชันอัปโหลดรูป Base64 (สายฟรี 100% ไม่ต้องใช้ Storage)
  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 15,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final Uint8List imageBytes = await image.readAsBytes();
      final String base64String = base64Encode(imageBytes);

      await FirebaseFirestore.instance
          .collection('plants')
          .doc(widget.plantId)
          .update({
            'timeline_updates': FieldValue.arrayUnion([
              {
                'image_base64': base64String,
                'timestamp': Timestamp.now(),
                'note': 'อัปเดตความเติบโต! 🌱',
              },
            ]),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เพิ่มรูปภาพสำเร็จ! 📸'),
            backgroundColor: Colors.green,
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
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.plantName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        // 🛠️ สเต็ปที่ 2: เพิ่มปุ่มแก้ไขตรงนี้!
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.green, size: 30),
            tooltip: 'แก้ไขข้อมูลต้นไม้',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPlantScreen(
                    plantId: widget.plantId,
                    currentData: widget.plantData,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('plants')
            .doc(widget.plantId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final List<dynamic> timelineUpdates = data['timeline_updates'] ?? [];

          timelineUpdates.sort(
            (a, b) => (b['timestamp'] as Timestamp).compareTo(
              a['timestamp'] as Timestamp,
            ),
          );

          DateTime? createdAt;
          if (data['created_at'] != null) {
            createdAt = (data['created_at'] as Timestamp).toDate();
          }
          String dateString = createdAt != null
              ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}'
              : 'Unknown';

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  color: Colors.grey[100],
                  child:
                      timelineUpdates.isNotEmpty &&
                          timelineUpdates.first['image_base64'] != null
                      ? Image.memory(
                          base64Decode(timelineUpdates.first['image_base64']),
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.local_florist,
                          size: 80,
                          color: Colors.grey,
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfo('Added Date', dateString),
                          _buildInfo('Frequency', data['frequency'] ?? '-'),
                        ],
                      ),
                      const Divider(height: 40),

                      const Text(
                        'Growth Timeline',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : _pickAndUploadImage,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.green,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_photo_alternate,
                                  color: Colors.black,
                                ),
                          label: Text(
                            _isUploading
                                ? 'กำลังอัปโหลด...'
                                : 'เพิ่มรูปจากแกลลอรี่',
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (timelineUpdates.isEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.yard_outlined,
                            color: Colors.grey,
                          ),
                          title: const Text('เริ่มปลูกน้องลงกระถาง 🌱'),
                          subtitle: Text(dateString),
                        ),

                      ...timelineUpdates.map((update) {
                        final dt = (update['timestamp'] as Timestamp).toDate();
                        final dateStr =
                            '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: Colors.grey[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: update['image_base64'] != null
                                  ? Image.memory(
                                      base64Decode(update['image_base64']),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.image, size: 50),
                            ),
                            title: Text(
                              update['note'] ?? 'อัปเดตความเติบโต!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(dateStr),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfo(String title, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ],
  );
}
