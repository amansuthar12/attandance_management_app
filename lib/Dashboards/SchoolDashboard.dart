import 'package:attandance_management_app/Student/addStudents.dart';
import 'package:attandance_management_app/Student/studetnList.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // Add this package for floating action button animations
import 'package:intl/intl.dart';

import '../Attendance/MarkAttendance.dart';
import '../Attendance/ViewAttendance.dart';
import '../Student/StudentListScreen.dart';
import '../teacher/addTeacher.dart';
import '../teacher/teacherList.dart';

class SchoolDashboard extends StatefulWidget {
  @override
  _SchoolDashboardState createState() => _SchoolDashboardState();
}

class _SchoolDashboardState extends State<SchoolDashboard> {
  int _selectedIndex = 0;
  int totalStudents = 0;
  int totalTeachers = 0;
  String schoolId = "";
  int presentStudents = 0;
  double pendingFees = 0.0;
  bool isNavigating = false;
  double dailyAttendancePercentage = 0.0;
  String schoolName = "Loading...";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final List<Widget> _widgetOptions = <Widget>[
    Center(child: Text("Dashboard Content")),
    // Assuming 'selectedClassID' and 'studentsList' are available
    MarkAttendance(
      schoolID: '', // Pass the schoolID here
      classID: '',
      // students: [], // Pass the list of students
    ),
    ViewAttendance(),
    Center(child: Text("Profile Content")),
  ];

  @override
  void initState() {
    super.initState();
    fetchSchoolData().then((_) {
      if (schoolId.isNotEmpty) {
        fetchStatistics(schoolId);
      }
    });
  }

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> fetchSchoolData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        if (!mounted) return; // Check if widget is still in the tree
        setState(() {
          schoolName = "No user logged in!";
        });
        return;
      }

      String userEmail = user.email!;
      print("Logged in user's email: $userEmail");

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Schools')
          .where('ContactInfo.Email', isEqualTo: userEmail)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var schoolData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        schoolId = querySnapshot.docs.first.id; // Get the school ID
        print("School ID: $schoolId");

        if (!mounted) return; // Ensure widget is still in the tree
        setState(() {
          schoolName = schoolData['SchoolName'] ?? "Unknown School";
        });
      } else {
        if (!mounted) return;
        setState(() {
          schoolName = "School not found!";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        schoolName = "Error fetching data!";
      });
      print("Error: $e");
    }
  }

  Future<void> fetchStatistics(String schoolId) async {
    if (schoolId.isEmpty) {
      print("Error: schoolId is empty. Cannot fetch statistics.");
      return;
    }

    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('Schools')
          .doc(schoolId)
          .collection('Students')
          .get();

      final attendanceCollection = FirebaseFirestore.instance
          .collection('Schools')
          .doc(schoolId)
          .collection('Attendance');

      final attendanceSnapshot = await attendanceCollection
          .where('date',
          isEqualTo: DateFormat('yyyy-MM-dd').format(DateTime.now())) // Today's date
          .get();

      int countedPresentStudents = 0; // Local variable for counting

      for (var doc in attendanceSnapshot.docs) {
        var attendanceData = doc.data() as Map<String, dynamic>;

        // ✅ Extract 'students' map
        if (attendanceData.containsKey('students')) {
          Map<String, dynamic> studentsMap =
          attendanceData['students'] as Map<String, dynamic>;

          // ✅ Count students with "present" status
          countedPresentStudents += studentsMap.values
              .where((status) => status == "present")
              .length;
        }
      }

      setState(() {
        totalStudents = studentsSnapshot.size;
        presentStudents = countedPresentStudents;
        dailyAttendancePercentage =
        totalStudents > 0 ? (presentStudents / totalStudents) * 100 : 0;
      });

      print("Total students: $totalStudents");
      print("Present students today: $presentStudents");
    } catch (e) {
      print("Error fetching statistics: $e");
    }
  }




  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Welcome, $schoolName",
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchSchoolData();
          await fetchStatistics(schoolId);
        },
        child: _selectedIndex == 0
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "Key Statistics",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final List<Map<String, dynamic>> stats = [
                          {
                            "title": "Total Students",
                            "value": totalStudents.toString(),
                            "icon": Icons.group,
                            "color": Colors.blue,
                            "onTap": () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      StudentListPage(schoolID: schoolId),
                                ),
                              );
                            },
                          },
                          {
                            "title": "Total Teachers",
                            "value": totalTeachers.toString(),
                            "icon": Icons.person,
                            "color": Colors.green,
                            "onTap": () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TeacherListPage(schoolID: schoolId),
                                ),
                              );
                            },
                          },
                          {
                            "title": "Attendance",
                            "value": "$presentStudents/$totalStudents Present",
                            "icon": Icons.check_circle_outline,
                            "color": Colors.orange,
                          },

                          {
                            "title": "Pending Fees",
                            "value": "₹${pendingFees.toStringAsFixed(2)}",
                            "icon": Icons.monetization_on,
                            "color": Colors.red,
                          },
                        ];

                        return _buildStatisticCard(
                          stats[index]['title'],
                          stats[index]['value'],
                          stats[index]['icon'],
                          stats[index]['color'],
                          onTap: stats[index]['onTap'],
                        );
                      },
                    ),
                  ],
                ),
              )
            : _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              label: "Mark Attendance",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: "Notifications",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.save_as), label: "Mark Attendance"),
          ],
          currentIndex: 0,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.green,
          onTap: (index) {
            if (index == 4) {
              showClassSelectionDialog(context, schoolId);
            }
          }),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Colors.blue,
        overlayOpacity: 0.5,
        children: [
          SpeedDialChild(
            child: Icon(Icons.person_add),
            label: "Add Student",
            backgroundColor: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddStudents(
                    schoolID: schoolId,
                    onStudentAdded: () {
                      fetchStatistics(schoolId);
                    },
                  ),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.person_outline),
            label: "Add Teacher",
            backgroundColor: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTeacherPage(
                    schoolID: schoolId,
                    onTeacherAdded: () {
                      fetchStatistics(
                          schoolId); // Refresh statistics immediately
                    },
                  ),
                ),
              );
            },
          ),
          SpeedDialChild(
              child: Icon(Icons.person_3),
              label: "class wise student",
              backgroundColor: Colors.green,
              onTap: () {
                showClassWiseStudents(context, schoolId);
              }),
        ],
      ),
    );
  }

  Widget _buildStatisticCard(
      String title, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showClassSelectionDialog(
      BuildContext context, String schoolID) async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Schools')
        .doc(schoolID)
        .collection('Students')
        .get();

    // Extract unique ClassIDs
    final Set<String> classIDs = snapshot.docs
        .map((doc) => doc.get('ClassID') as String? ?? 'Unknown')
        .where((classID) => classID != 'Unknown') // Remove unknown values
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
                      // Debugging line to check if classID is being selected
                      print('Selected ClassID: $classID'); // Debugging line

                      Navigator.of(context).pop();
                      showStudentList(context, schoolID, classID);
                    },
                  );
                }),
          ),
        );
      },
    );
  }

  Future<void> showStudentList(
      BuildContext context, String schoolID, String classID) async {
    print('Navigating to StudentListScreen for ClassID: $classID');

    // Just navigate — do not fetch students here
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkAttendance(
          schoolID: schoolID,
          classID: classID,
        ),
      ),
    );
  }

  //
  // Future<void> showStudentList(BuildContext context, String schoolID,
  //     String classID) async {
  //   print('Fetching students for ClassID: $classID');
  //
  //   try {
  //     // Fetch students from Firestore based on classID
  //     final QuerySnapshot snapshot = await FirebaseFirestore.instance
  //         .collection('Schools')
  //         .doc(schoolID)
  //         .collection('Students')
  //         .where('ClassID', isEqualTo: classID.toString())
  //         .get();
  //
  //     print('Total fetched documents: ${snapshot.docs.length}');
  //
  //     if (snapshot.docs.isEmpty) {
  //       print('No students found for ClassID: $classID');
  //     }
  //
  //     // Map the fetched documents to a list of student data
  //     List<Map<String, dynamic>> studentList = snapshot.docs.map((doc) {
  //       final data = doc.data() as Map<String, dynamic>;
  //       print('Fetched Student: ${data['Name']}, ClassID: ${data['ClassID']}');
  //       return {
  //         'Name': data['Name'] ?? 'Unknown',
  //         'RollNumber': data['RollNumber'] ?? 'N/A',
  //         'StudentID': doc.id,
  //         'ClassID': data['ClassID'] ?? 'Unknown',
  //       };
  //     }).toList();
  //
  //     // Ensure the context is still mounted before navigation
  //     if (mounted && !isNavigating) {
  //       print('Context is still mounted, navigating to StudentListScreen...');
  //       setState(() {
  //         isNavigating = true; // Prevent multiple navigation attempts
  //       });
  //
  //       // Schedule navigation after the current frame to avoid errors
  //       WidgetsBinding.instance.addPostFrameCallback((_) {
  //         if (!mounted) return; // Ensure widget is still active
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => StudentListPage(schoolID: schoolId),
  //           ),
  //         );
  //
  //       });
  //     }
  //   } catch (e) {
  //     print('Error fetching students: $e');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error fetching students: $e')),
  //       );
  //     }
  //   }
  // }

  Future<void> showClassWiseStudents(
      BuildContext context, String schoolID) async {
    final parentContext = context;

    // Show loading indicator
    // showDialog(
    //   context: parentContext,
    //   barrierDismissible: false,
    //   builder: (context) => const Center(child: CircularProgressIndicator()),
    // );

    try {
      // Fetch all students from Firestore
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Schools')
          .doc(schoolID)
          .collection('Students')
          .get();

      // Close the loading spinner if context is still mounted
      if (parentContext.mounted) {
        Navigator.of(parentContext).pop();
      }

      // Check if students exist
      if (snapshot.docs.isNotEmpty) {
        // Group students by class
        Map<String, List<Map<String, dynamic>>> classWiseStudents = {};

        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String className = data['Class'] ?? 'Unknown';

          if (!classWiseStudents.containsKey(className)) {
            classWiseStudents[className] = [];
          }
          classWiseStudents[className]!.add(data);
        }

        // Show dialog with class-wise students
        if (parentContext.mounted) {
          showDialog(
            context: parentContext,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Class-wise Student List'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    children: classWiseStudents.keys.map((ClassID) {
                      return ExpansionTile(
                        title: Text(
                          'Class $ClassID',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        children: classWiseStudents[ClassID]!.map((student) {
                          return ListTile(
                            title: Text(student['Name'] ?? 'Unknown'),
                            subtitle:
                                Text('Roll No: ${student['RollNo'] ?? 'N/A'}'),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        if (parentContext.mounted) {
          showDialog(
            context: parentContext,
            builder: (context) => AlertDialog(
              title: const Text('No Students Found'),
              content: const Text('No students are registered in the system.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print("Error fetching class-wise students: $e");
    }
  }
}
