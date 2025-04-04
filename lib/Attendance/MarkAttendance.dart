import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MarkAttendance extends StatefulWidget {
  final String schoolID;
  final String classID;
  final String? teacherID;
  const MarkAttendance({
    required this.schoolID,
    required this.classID,
     this.teacherID,
  });

  @override
  State<MarkAttendance> createState() => _MarkAttendanceState();
}

class _MarkAttendanceState extends State<MarkAttendance> {
  List<Map<String, dynamic>> students = [];
  Map<String, bool> attendanceStatus = {}; // Student ID -> Present/Absent
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  String? selectedSubject;
  String? selectedLecture;
  List<String> subjects = ["Math", "Science", "English", "History"];
  List<String> lectures = ["1", "2", "3", "4", "5"];

  @override
  void initState() {
    super.initState();
    fetchStudents();
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

        // Initialize all as "absent"
        for (var student in students) {
          attendanceStatus[student['StudentID']] = false;
        }

        isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching students: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> checkExistingAttendance() async {
    if (selectedSubject == null || selectedLecture == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select subject and lecture first")),
      );
      return;
    }

    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    String attendanceDocID = "${formattedDate}_${widget.classID}_${selectedSubject}_${selectedLecture}";

    final attendanceDoc = await FirebaseFirestore.instance
        .collection('Schools')
        .doc(widget.schoolID)
        .collection('Attendance')
        .doc(attendanceDocID)
        .get();

    if (attendanceDoc.exists) {
      final data = attendanceDoc.data()!;
      final storedAttendance = data['students'] as Map<String, dynamic>;

      setState(() {
        attendanceStatus = storedAttendance.map((key, value) => MapEntry(key, value == "present"));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Attendance already marked! Showing existing data.")),
      );
    }
  }

  Future<void> saveAttendance() async {
    if (selectedSubject == null || selectedLecture == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select subject and lecture first")),
      );
      return;
    }

    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    String attendanceDocID = "${formattedDate}_${widget.classID}_${selectedSubject}_${selectedLecture}";

    Map<String, String> attendanceData = {};
    for (var student in students) {
      attendanceData[student['StudentID']] = attendanceStatus[student['StudentID']]! ? "present" : "absent";
    }

    String markedBy = "School"; // Default value

    if (widget.teacherID != null) {
      try {
        // 🔥 Fetch Teacher Name from Firestore
        DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
            .collection('Schools')
            .doc(widget.schoolID)
            .collection('Teachers')
            .doc(widget.teacherID)
            .get();

        if (teacherDoc.exists) {
          markedBy = teacherDoc['Name'] ?? "Unknown Teacher";
        } else {
          markedBy = "Unknown Teacher";
        }
      } catch (e) {
        print("❌ Error fetching teacher name: $e");
        markedBy = "Unknown Teacher";
      }
    }

    await FirebaseFirestore.instance
        .collection('Schools')
        .doc(widget.schoolID)
        .collection('Attendance')
        .doc(attendanceDocID)
        .set({
      'date': formattedDate,
      'classId': widget.classID,
      'subject': selectedSubject,
      'lecture': selectedLecture,
      'students': attendanceData,
      'markedBy': markedBy,  // 🔥 Store Teacher Name or "School"
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Attendance marked successfully')),
    );
  }






  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (students.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No students found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Mark Attendance")),
      body: Column(
        children: [
          // 📅 Date Picker
          ListTile(
            title: Text("Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
            trailing: Icon(Icons.calendar_today),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
              );
              if (pickedDate != null) {
                setState(() => selectedDate = pickedDate);
              }
            },
          ),

          // 📚 Subject Dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Select Subject"),
            value: selectedSubject,
            items: subjects.map((subject) {
              return DropdownMenuItem<String>(
                value: subject,
                child: Text(subject),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => selectedSubject = value);
            },
          ),

          // 🎓 Lecture Dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Select Lecture"),
            value: selectedLecture,
            items: lectures.map((lecture) {
              return DropdownMenuItem<String>(
                value: lecture,
                child: Text("Lecture $lecture"),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => selectedLecture = value);
            },
          ),

          ElevatedButton(
            onPressed: checkExistingAttendance,
            child: const Text("🔍 Check Attendance"),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return CheckboxListTile(
                  title: Text(student['Name']),
                  subtitle: Text('Roll No: ${student['RollNumber']}'),
                  value: attendanceStatus[student['StudentID']],
                  onChanged: (bool? value) {
                    setState(() {
                      attendanceStatus[student['StudentID']] = value!;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: saveAttendance,
        child: const Icon(Icons.save),
      ),
    );
  }
}


// }
  // @override
  // Widget build(BuildContext context) {
  //   if (isLoading) {
  //     return const Scaffold(
  //       body: Center(child: CircularProgressIndicator()),
  //     );
  //   }
  //
  //   if (students.isEmpty) {
  //     return const Scaffold(
  //       body: Center(child: Text('No students found.')),
  //     );
  //   }
  //
  //   return Scaffold(
  //     appBar: AppBar(title: const Text("Mark Attendance")),
  //     body: ListView.builder(
  //       itemCount: students.length,
  //       itemBuilder: (context, index) {
  //
  //         final student = students[index];
  //         print("Student Data: ${student.toString()}");
  //         final Map<String, dynamic>? parentContact = student['ParentContact'] as Map<String, dynamic>?;
  //         final String email = parentContact?['Email'] ?? 'No email';
  //         final String phone = parentContact?['Phone'] ?? 'No phone';
  //
  //         return ListTile(
  //           title: Text(student['name']),
  //           subtitle: Text('ID: ${student['id']}'),
  //         );
  //       },
  //     ),
  //   );
  // }
//}






//
// class MarkAttendance extends StatefulWidget {
//   final String schoolID;
//   final String classID;
//   // final List<Map<String, dynamic>> students;  // Define the parameter
//
//   MarkAttendance({
//     required this.schoolID,
//     required this.classID,
//   });
//
//   @override
//   State<MarkAttendance> createState() => _MarkAttendanceState();
// }
//
// class _MarkAttendanceState extends State<MarkAttendance> {
//   final Map<String, Map<String, Map<String, int>>> attendanceMap = {};
//   final TextEditingController dateController = TextEditingController();
//   DateTime? selectedDate;
//   String? selectedClass;
//   String? selectedSubject;
//
//   List<String> classList = [];
//   List<Map<String, dynamic>> students = []; // List to store fetched students
//
//   final List<String> subjects = [
//     'Math', 'Science', 'History', 'English', 'Geography',
//     'Music', 'Art', 'PE', 'Cooking',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchClasses();
//   }
//
//   // Fetch available classes from Firestore
//   _fetchClasses() async {
//     final classData = await FirebaseFirestore.instance
//         .collection('Schools')
//         .doc(widget.schoolID) // Use actual school ID
//         .collection('Classes')
//         .get();
//
//     setState(() {
//       classList = classData.docs.map((doc) => doc['className'].toString()).toList();
//     });
//   }
//
//   // Fetch students for the selected class
//   _fetchStudents() async {
//     if (selectedClass == null) return;
//
//     print('Fetching students for ClassID: $selectedClass');
//
//     final QuerySnapshot snapshot = await FirebaseFirestore.instance
//         .collection('Schools')
//         .doc(widget.schoolID)
//         .collection('Students')
//         .where('ClassID', isEqualTo: selectedClass)
//         .get();
//
//     setState(() {
//       students = snapshot.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         print('Fetched Student: ${data['Name']}, ClassID: ${data['ClassID']}');
//         return {
//           'Name': data['Name'] ?? 'Unknown',
//           'RollNumber': data['RollNumber'] ?? 'N/A',
//           'StudentID': doc.id,
//           'ImageUrl': data['ImageUrl'] ?? 'https://via.placeholder.com/150',
//         };
//       }).toList();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: dateController,
//                     readOnly: true,
//                     decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
//                     onTap: () async {
//                       DateTime? pickedDate = await showDatePicker(
//                         context: context,
//                         initialDate: DateTime.now(),
//                         firstDate: DateTime(2000),
//                         lastDate: DateTime(2101),
//                       );
//                       if (pickedDate != null) {
//                         setState(() {
//                           selectedDate = pickedDate;
//                           dateController.text =
//                               DateFormat('yyyy-MM-dd').format(pickedDate);
//                         });
//                       }
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 DropdownButton<String>(
//                   hint: const Text('Select Class'),
//                   value: selectedClass,
//                   onChanged: (String? newValue) {
//                     setState(() {
//                       selectedClass = newValue;
//                       students.clear(); // Clear old student list
//                     });
//                     _fetchStudents(); // Fetch new students
//                   },
//                   items: classList.map<DropdownMenuItem<String>>((String value) {
//                     return DropdownMenuItem<String>(
//                       value: value,
//                       child: Text(value),
//                     );
//                   }).toList(),
//                 ),
//                 const SizedBox(width: 16),
//                 DropdownButton<String>(
//                   hint: const Text('Select Subject'),
//                   value: selectedSubject,
//                   onChanged: (String? newValue) {
//                     setState(() {
//                       selectedSubject = newValue;
//                     });
//                   },
//                   items: subjects.map<DropdownMenuItem<String>>((String value) {
//                     return DropdownMenuItem<String>(
//                       value: value,
//                       child: Text(value),
//                     );
//                   }).toList(),
//                 ),
//               ],
//             ),
//           ),
//           if (selectedClass != null) ...[
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Text(
//                 'Selected Class: $selectedClass',
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//           Expanded(
//             child: students.isEmpty
//                 ? const Center(child: Text('No students found.'))
//                 : ListView.builder(
//               itemCount: students.length,
//               itemBuilder: (context, index) {
//                 var student = students[index];
//
//                 return Card(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 4,
//                   margin: const EdgeInsets.symmetric(vertical: 6),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundImage: NetworkImage(student['ImageUrl']),
//                     ),
//                     title: Text(
//                       student['Name'],
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     subtitle: Text(
//                       "Roll No: ${student['RollNumber']}",
//                       style: const TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: saveAttendance,
//         child: const Icon(Icons.save),
//       ),
//     );
//   }
//
//   void saveAttendance() async {
//     final date = dateController.text.trim();
//
//     if (date.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter the date')),
//       );
//       return;
//     }
//
//     if (selectedSubject == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a subject')),
//       );
//       return;
//     }
//
//     try {
//       WriteBatch batch = FirebaseFirestore.instance.batch();
//
//       bool alreadyMarked = false;
//
//       attendanceMap.forEach((userId, attendanceData) {
//         var subjectData = attendanceData[date];
//         if (subjectData != null && subjectData.containsKey(selectedSubject!)) {
//           alreadyMarked = true;
//           return;
//         }
//       });
//
//       if (alreadyMarked) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Attendance already marked for this subject on $date')),
//         );
//         return;
//       }
//
//       attendanceMap.forEach((userId, attendanceData) {
//         DocumentReference userRef =
//         FirebaseFirestore.instance.collection('users').doc(userId);
//         int status = attendanceData[date]?[selectedSubject!] ?? 1;
//         batch.update(userRef, {'attendance.$date.${selectedSubject!}': status});
//       });
//
//       await batch.commit();
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Attendance updated successfully')),
//       );
//     } catch (e) {
//       print('Error updating attendance: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to update attendance')),
//       );
//     }
//   }
// }
