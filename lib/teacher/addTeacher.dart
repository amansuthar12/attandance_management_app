import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddTeacherPage extends StatefulWidget {
  final String schoolID;
  final VoidCallback onTeacherAdded;

  AddTeacherPage({required this.schoolID, required this.onTeacherAdded});

  @override
  _AddTeacherState createState() => _AddTeacherState();
}

class _AddTeacherState extends State<AddTeacherPage> {
  final _formKey = GlobalKey<FormState>();

  // Text Editing Controllers for Required Fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _teacherIDController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _joiningDateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Text Editing Controllers for Additional Fields
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _languagesController = TextEditingController();
  final TextEditingController _hobbiesController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  Future<void> _addTeacher() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await FirebaseFirestore.instance
            .collection('Schools')
            .doc(widget.schoolID)
            .collection('Teachers')
            .doc(_teacherIDController.text)
            .set({
          'TeacherID': _teacherIDController.text,
          'Name': _nameController.text,
          'Subject': _subjectController.text,
          'Phone': _phoneController.text,
          'Password': _passwordController.text.trim(),
          'Email': _emailController.text,
          'JoiningDate': _joiningDateController.text,
          'Qualification': _qualificationController.text,
          'Experience': _experienceController.text,
          'Languages': _languagesController.text,
          'Hobbies': _hobbiesController.text,
          'BloodGroup': _bloodGroupController.text,
          'Address': _addressController.text,
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher added successfully!')),
        );

        // Clear the form
        _nameController.clear();
        _teacherIDController.clear();
        _subjectController.clear();
        _phoneController.clear();
        _emailController.clear();
        _joiningDateController.clear();
        _qualificationController.clear();
        _experienceController.clear();
        _languagesController.clear();
        _hobbiesController.clear();
        _passwordController.clear();

        _bloodGroupController.clear();
        _addressController.clear();

        widget.onTeacherAdded();
        Navigator.pop(context);
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add teacher: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Teacher'),
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
                    labelText: 'Teacher Name',
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a name' : null,
                ),
                TextFormField(
                  controller: _teacherIDController,
                  decoration: const InputDecoration(
                    labelText: 'Teacher ID',
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a teacher ID' : null,
                ),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Specialization',
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter the subject' : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter a phone number'
                      : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter an email address'
                      : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a password' : null,
                ),

                TextFormField(
                  controller: _joiningDateController,
                  decoration: const InputDecoration(
                    labelText: 'Joining Date',
                  ),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter the joining date'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _qualificationController,
                  decoration: const InputDecoration(
                    labelText: 'Qualification',
                  ),
                ),
                TextFormField(
                  controller: _experienceController,
                  decoration: const InputDecoration(
                    labelText: 'Experience (Years)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _languagesController,
                  decoration: const InputDecoration(
                    labelText: 'Languages Known',
                  ),
                ),
                TextFormField(
                  controller: _hobbiesController,
                  decoration: const InputDecoration(
                    labelText: 'Hobbies',
                  ),
                ),
                TextFormField(
                  controller: _bloodGroupController,
                  decoration: const InputDecoration(
                    labelText: 'Blood Group',
                  ),
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addTeacher,
                  child: const Text('Add Teacher'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
