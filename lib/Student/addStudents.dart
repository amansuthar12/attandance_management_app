import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddStudents extends StatefulWidget {
  final String schoolID;
  final VoidCallback onStudentAdded;

  AddStudents({required this.schoolID, required this.onStudentAdded});

  @override
  _AddStudentsState createState() => _AddStudentsState();
}

class _AddStudentsState extends State<AddStudents> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentIDController = TextEditingController();
  final TextEditingController _classIDController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _parentEmailController = TextEditingController();

  Future<void> _addStudent() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Add student to Firestore under the correct school document and students subcollection
        DocumentReference studentRef = FirebaseFirestore.instance
            .collection('Schools')
            .doc(widget.schoolID)
            .collection('Students')
            .doc(); // Firestore will auto-generate the document ID

        await studentRef.set({
          'StudentID': studentRef.id, // Use the auto-generated ID for the student
          'Name': _nameController.text,
          'ClassID': _classIDController.text,
          'RollNumber': _rollNumberController.text,
          'ParentContact': {
            'Phone': _parentPhoneController.text,
            'Email': _parentEmailController.text,
          },
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully!')),
        );

        // Clear the form
        _nameController.clear();
        _studentIDController.clear();
        _classIDController.clear();
        _rollNumberController.clear();
        _parentPhoneController.clear();
        _parentEmailController.clear();

        // Trigger the callback to update UI in parent widget
        widget.onStudentAdded();

        // Close the Add Students screen
        Navigator.pop(context);
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add student: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Students'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a name' : null,
                ),
                TextFormField(
                  controller: _studentIDController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID',
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true
                      ? 'Please enter a student ID'
                      : null,
                ),
                TextFormField(
                  controller: _classIDController,
                  decoration: const InputDecoration(
                    labelText: 'Class ID',
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a class ID' : null,
                ),
                TextFormField(
                  controller: _rollNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Roll Number',
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true
                      ? 'Please enter a roll number'
                      : null,
                ),
                TextFormField(
                  controller: _parentPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Parent Phone',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                  value?.isEmpty ?? true
                      ? 'Please enter a parent\'s phone number'
                      : null,
                ),
                TextFormField(
                  controller: _parentEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Parent Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                  value?.isEmpty ?? true
                      ? 'Please enter a parent\'s email'
                      : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addStudent,
                  child: const Text('Add Student'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
