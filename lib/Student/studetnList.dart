import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentListPage extends StatelessWidget {
  final String schoolID;

  StudentListPage({required this.schoolID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Students List"),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Schools')
            .doc(schoolID)
            .collection('Students')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Failed to load students"),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No students found"),
            );
          }

          final students = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index].data() as Map<String, dynamic>;
              final studentName = student['Name'] ?? 'Unknown';
              final studentId = student['StudentID'] ?? 'Unknown';
              final studentRollNumber = student['RollNumber'] ?? 'N/A';
              final studentImage = student['ImageUrl'] ??
                  'https://via.placeholder.com/150'; // Placeholder image

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(studentImage),
                    onBackgroundImageError: (error, stackTrace) {
                      // Use placeholder icon on image error
                      // return const Icon(Icons.person);
                    },
                    radius: 24,
                  ),
                  title: Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Roll No: $studentRollNumber",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'Edit':
                          _editStudent(context, schoolID, studentId, student);
                          break;
                        case 'Delete':
                          _deleteStudent(context, schoolID, studentId);
                          break;
                        case 'View Details':
                          _viewStudentDetails(context, student);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'View Details',
                        child: Text('View Details'),
                      ),
                      const PopupMenuItem(
                        value: 'Edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'Delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _editStudent(
      BuildContext context, String schoolID, String studentID, Map student) {

    print("Edit student: $studentID");
  }

  void _deleteStudent(BuildContext context, String schoolID, String studentID) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Student"),
        content: const Text("Are you sure you want to delete this student?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('Schools')
                    .doc(schoolID)
                    .collection('Students')
                    .doc(studentID)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Student deleted successfully")),
                );
              } catch (e) {
                print("Failed to delete student: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to delete student")),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _viewStudentDetails(BuildContext context, Map student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Student Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${student['Name'] ?? 'N/A'}"),
            Text("ClassID: ${student['ClassID'] ?? 'N/A'}"),
            Text("Roll No: ${student['RollNumber'] ?? 'N/A'}"),
            Text("StudentID: ${student['StudentID'] ?? 'N/A'}"),
            Text(
                "Parent Phone: ${student['ParentContact']?['Phone'] ?? 'N/A'}"),
            Text(
                "Parent Email: ${student['ParentContact']?['Email'] ?? 'N/A'}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
