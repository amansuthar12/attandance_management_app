import 'package:attandance_management_app/authntication/SchoolRegistration.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ATTENDANCE MANAGEMENT SYSTEM',
      home: SchoolRegistration(),
      // initialRoute: "/signUp",
      // routes: {
      //   '/signUp': (context) => const signUp(),
      // },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // home: signUp(title: 'Attendance Management System'),
    );
  }
}
