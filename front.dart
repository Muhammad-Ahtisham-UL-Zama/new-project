import 'package:flutter/material.dart';
import 'database_helper_api.dart';

class AddResultPage extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const AddResultPage({
    Key? key,
    required this.studentData,
  }) : super(key: key);

  @override
  _AddResultPageState createState() => _AddResultPageState();
}

class _AddResultPageState extends State<AddResultPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Form controllers
  String? _selectedCourse;
  final TextEditingController _marksController = TextEditingController();
  String? _selectedSemester;
  String? _selectedCreditHours;

  // Available options
  final List<String> _courses = [
    'CS101 - Introduction to Computing',
    'CS201 - Programming Fundamentals',
    'CS301 - Data Structures',
    'CS401 - Algorithms',
    'CS501 - Database Systems',
    'CS601 - Web Development',
    'CS701 - Mobile App Development',
    'CS801 - Artificial Intelligence',
    'PHYS-5127 - Applied Physics/Quantum Computing',
  ];

  final List<String> _semesters = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th'];
  final List<String> _creditHours = ['1', '2', '3', '4'];

  @override
  void dispose() {
    _marksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Result'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Course',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCourse,
                items: _courses.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) => value == null ? 'Please select a course' : null,
                onChanged: (newValue) {
                  setState(() {
                    _selectedCourse = newValue;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Marks Input
              TextFormField(
                controller: _marksController,
                decoration: const InputDecoration(
                  labelText: 'Obtained Marks (out of 100)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter marks';
                  }
                  final marks = double.tryParse(value);
                  if (marks == null || marks < 0 || marks > 100) {
                    return 'Please enter valid marks (0-100)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Semester Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  border: OutlineInputBorder(),
                ),
                value: _selectedSemester,
                items: _semesters.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) => value == null ? 'Please select a semester' : null,
                onChanged: (newValue) {
                  setState(() {
                    _selectedSemester = newValue;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Credit Hours Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Credit Hours',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCreditHours,
                items: _creditHours.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) => value == null ? 'Please select credit hours' : null,
                onChanged: (newValue) {
                  setState(() {
                    _selectedCreditHours = newValue;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Submit Result',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Split course into code and title
        final courseParts = _selectedCourse!.split(' - ');
        final courseCode = courseParts[0];
        final courseTitle = courseParts[1];

        // Determine consider_status based on semester
        final semesterNumber = _selectedSemester!.replaceAll(RegExp(r'[^0-9]'), '');
        final considerStatus = (int.tryParse(semesterNumber) ?? 0) >= 6 ? 'NA' : 'E';

        // Calculate grade
        final marks = double.parse(_marksController.text);
        final grade = _calculateGrade(marks, considerStatus);

        // Prepare the result data
        final resultData = {
          ...widget.studentData,
          'coursecode': courseCode,
          'coursetitle': courseTitle,
          'obtainedmarks': marks.toString(),
          'mysemester': _selectedSemester,
          'credithours': _selectedCreditHours,
          'totalmarks': 100,
          'grade': grade,
          'consider_status': considerStatus,
          'is_deleted': 0,
        };

        // Insert into database and get the inserted record
        final id = await _dbHelper.insertStudentResult(resultData);
        final completeRecord = {
          ...resultData,
          'id': id,  // Include the auto-generated ID
        };

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Result added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return the complete record including ID
        Navigator.pop(context, completeRecord);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding result: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _calculateGrade(double marks, String considerStatus) {
    if (considerStatus == 'NA') return 'NA';
    if (marks >= 80) return 'A';
    if (marks >= 65) return 'B';
    if (marks >= 50) return 'C';
    return 'F';
  }
}