import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Attendance/MarkAttendance.dart';
import '../authntication/Login.dart';

class TeacherDashboard extends StatefulWidget {
  final String schoolId;
  final String teacherId;



  TeacherDashboard({required this.schoolId, required this.teacherId});

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  Map<String, dynamic>? teacherData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTeacherData();
  }

  Future<void> fetchTeacherData() async {
    try {
      DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
          .collection('Schools')
          .doc(widget.schoolId)
          .collection('Teachers')
          .doc(widget.teacherId)
          .get();

      if (teacherDoc.exists) {
        setState(() {
          teacherData = teacherDoc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Teacher not found!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
  }

  // 📦 New: Class selection logic
  Future<void> showClassSelectionDialog(BuildContext context, String schoolID) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Schools')
        .doc(schoolID)
        .collection('Students')
        .get();



    final Set<String> classIDs = snapshot.docs
        .map((doc) => doc.get('ClassID') as String? ?? 'Unknown')
        .where((classID) => classID != 'Unknown')
        .toSet();

    if (classIDs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No classes found!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Class'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: classIDs.length,
              itemBuilder: (context, index) {
                final classID = classIDs.elementAt(index);
                return ListTile(
                  title: Text('Class $classID'),
                  onTap: () {
                    Navigator.of(context).pop();
                    showStudentList(context, schoolID, classID);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> showStudentList(BuildContext context, String schoolID, String classID) async {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkAttendance(
          schoolID: schoolID,
          classID: classID,
          teacherID: widget.teacherId,
        ),
      ),
    );

  }

  Widget _buildDashboardCard(String title, IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        color: Colors.blue.shade50,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : teacherData == null
          ? Center(child: Text("No data found"))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildDashboardCard("Mark Attendance", Icons.checklist, onTap: () {
              // Open class selection dialog instead of using teacherData['classID']
              showClassSelectionDialog(context, widget.schoolId);
            }),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text("$label: ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
