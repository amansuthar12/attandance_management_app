import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherListPage extends StatelessWidget {
  final String schoolID;

  TeacherListPage({required this.schoolID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher List"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ), // Enables back button automatically
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Schools')
            .doc(schoolID)
            .collection('Teachers')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Failed to load Teachers"),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No Teachers found"),
            );
          }

          final teachers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final teacher = teachers[index].data() as Map<String, dynamic>;
              final teacherName = teacher['Name'] ?? 'Unknown';
              final teacherPhoneNumber = teacher['Phone'] ?? 'N/A';
              final teacherImage = teacher['ImageUrl'] ??
                  'https://via.placeholder.com/150'; // Placeholder image

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(teacherImage),
                    onBackgroundImageError: (_, __) {
                      // Use placeholder icon if the image fails to load
                    },
                  ),
                  title: Text(
                    teacherName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Phone No: $teacherPhoneNumber",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'Edit':
                          _editTeacher(context, schoolID, teachers[index].id);
                          break;
                        case 'Delete':
                          _deleteTeacher(context, schoolID, teachers[index].id);
                          break;
                        case 'View Details':
                          _viewTeacherDetails(context, teacher);
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

  void _editTeacher(BuildContext context, String schoolID, String teacherID) {
    // Navigate to an edit teacher page or show an editing dialog
    print("Edit Teacher: $teacherID");
  }

  void _deleteTeacher(BuildContext context, String schoolID, String teacherID) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Teacher"),
        content: const Text("Are you sure you want to delete this teacher?"),
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
                    .collection('Teachers')
                    .doc(teacherID)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Teacher deleted successfully")),
                );
              } catch (e) {
                print("Failed to delete teacher: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to delete teacher")),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _viewTeacherDetails(BuildContext context, Map<String, dynamic> teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Teacher Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${teacher['Name'] ?? 'N/A'}"),
            Text("Phone: ${teacher['Phone'] ?? 'N/A'}"),
            Text("Email: ${teacher['Email'] ?? 'N/A'}"),
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
