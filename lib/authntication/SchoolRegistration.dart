import 'package:attandance_management_app/Dashboards/SchoolDashboard.dart';
import 'package:attandance_management_app/authntication/Login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SchoolRegistration extends StatefulWidget {
  const SchoolRegistration({Key? key}) : super(key: key);

  @override
  _SchoolRegistrationState createState() => _SchoolRegistrationState();
}

class _SchoolRegistrationState extends State<SchoolRegistration> {
  // Controllers
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController schoolNameController = TextEditingController();
  final TextEditingController registrationNumberController =
      TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController principalNameController = TextEditingController();
  final TextEditingController principalPhoneController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Password visibility toggle
  bool _isPasswordHidden = true;

  // Form Key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Function to register principal and school
  Future<void> registerSchool() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Register the principal in Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      String principalUID = userCredential.user!.uid;

      // Generate a unique SchoolID
      String schoolID = _firestore.collection('Schools').doc().id;

      // Add school data to Firestore
      await _firestore.collection('Schools').doc(schoolID).set({
        "SchoolName": schoolNameController.text,
        "RegistrationNumber": registrationNumberController.text,
        "Address": addressController.text,
        "ContactInfo": {
          "Phone": principalPhoneController.text,
          "Email": emailController.text,
        },
        "PrincipalInfo": {
          "PrincipalName": principalNameController.text,
          "PrincipalEmail": emailController.text,
          "PrincipalPhone": principalPhoneController.text,
          "PrincipalUID": principalUID,
        },
        "CreatedAt": FieldValue.serverTimestamp(),
        "Status": true, // Active by default
      });

      // Success Message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School registered successfully!')),
      );
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => SchoolDashboard()));

      // Clear all fields
      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Clear input fields
  void _clearFields() {
    schoolNameController.clear();
    registrationNumberController.clear();
    addressController.clear();
    emailController.clear();
    passwordController.clear();
    principalNameController.clear();
    principalPhoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [Color(0xff1b56ea), Color(0xffffffff)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.05),
                  const Text(
                    "Register Your School",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  reusableTextField(
                    "School Name",
                    Icons.school,
                    false,
                    schoolNameController,
                  ),
                  reusableTextField(
                    "Registration Number",
                    Icons.numbers,
                    false,
                    registrationNumberController,
                  ),
                  reusableTextField(
                    "Address",
                    Icons.location_on,
                    false,
                    addressController,
                  ),
                  reusableTextField(
                    "Principal Name",
                    Icons.person,
                    false,
                    principalNameController,
                  ),
                  reusableTextField(
                    "Principal Phone",
                    Icons.phone,
                    false,
                    principalPhoneController,
                  ),
                  reusableTextField(
                    "Email",
                    Icons.email,
                    false,
                    emailController,
                  ),
                  reusableTextField(
                    "Password",
                    Icons.lock,
                    true,
                    passwordController,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordHidden = !_isPasswordHidden;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  ElevatedButton(
                    onPressed: registerSchool,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: const Color(0xff1b56ea),
                    ),
                    child: const Text(
                      "Register School",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  SizedBox(
                    height: size.height * 0.03,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Login()),
                        );
                      },
                      child: Text("login"))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Padding reusableTextField(
    String labelText,
    IconData icon,
    bool isPassword,
    TextEditingController controller, {
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _isPasswordHidden : false,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "$labelText is required";
          }
          return null;
        },
      ),
    );
  }
}
