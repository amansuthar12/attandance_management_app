import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentListScreen extends StatefulWidget {
  final String schoolID;
  final String classID;

  const StudentListScreen({
    super.key,
    required this.schoolID,
    required this.classID,
  });

  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents(); // Fetch data when screen opens
  }

  Future<void> fetchStudents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Schools')
          .doc(widget.schoolID)
          .collection('Students')
          .where('ClassID', isEqualTo: widget.classID)
          .get();

      setState(() {
        students = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'Name': data['Name'] ?? 'Unknown',
            'RollNumber': data['RollNumber'] ?? 'N/A',
            'StudentID': doc.id,
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching students: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching students')),
        );
      }
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Students in Class ${widget.classID}')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : students.isEmpty
          ? const Center(child: Text('No students found'))
          : ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return ListTile(
            title: Text(student['Name']),
            subtitle: Text('Roll No: ${student['RollNumber']}'),
          );
        },
      ),
    );
  }
}
