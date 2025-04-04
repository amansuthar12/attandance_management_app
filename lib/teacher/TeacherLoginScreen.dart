import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'TeacherDashboard.dart';

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _loginTeacher() async {
    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      final schoolsSnapshot = await FirebaseFirestore.instance.collection('Schools').get();

      DocumentSnapshot? matchedTeacherDoc;
      String? schoolId;

      for (var school in schoolsSnapshot.docs) {
        final teachersSnapshot = await FirebaseFirestore.instance
            .collection('Schools')
            .doc(school.id)
            .collection('Teachers')
            .where('Email', isEqualTo: email)
            .where('Password', isEqualTo: password)
            .get();

        if (teachersSnapshot.docs.isNotEmpty) {
          matchedTeacherDoc = teachersSnapshot.docs.first;
          schoolId = school.id;
          break;
        }
      }

      if (matchedTeacherDoc != null && schoolId != null) {
        final data = matchedTeacherDoc.data() as Map<String, dynamic>;
        final teacherId = data['TeacherID'] ?? '';

        // Navigate to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherDashboard(
              schoolId: schoolId!,
              teacherId: teacherId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid credentials. Please try again.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _loginTeacher,
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
