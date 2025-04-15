import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart'; // add this at the top
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';


class AddGradePage extends StatefulWidget {
  @override
  _AddGradePageState createState() => _AddGradePageState();
}

class _AddGradePageState extends State<AddGradePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  // Form controllers for submission
  final _submitUserIdController = TextEditingController();
  final _semesterNoController = TextEditingController();
  final _creditHoursController = TextEditingController();
  final _marksController = TextEditingController();

  // Controller for fetching grades
  final _fetchUserIdController = TextEditingController();

  // For displaying grades
  List<dynamic> _gradesData = [];
  bool _isFetchingGrades = false;
  String _gradesError = '';

  // For course dropdown
  List<dynamic> _courses = [];
  String? _selectedCourseId;
  String? _selectedCourseName;
  bool _isLoadingCourses = false;
  String _coursesError = '';

  @override
  void initState() {
    super.initState();
    // Listen for changes in user ID to fetch courses
    _submitUserIdController.addListener(_onUserIdChanged);
  }

  @override
  void dispose() {
    _submitUserIdController.removeListener(_onUserIdChanged);
    _submitUserIdController.dispose();
    _fetchUserIdController.dispose();
    _semesterNoController.dispose();
    _creditHoursController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  void _onUserIdChanged() {
    final userId = _submitUserIdController.text.trim();
    if (userId.isNotEmpty) {
      _fetchCoursesByUserId(userId);
    } else {
      setState(() {
        _courses = [];
        _selectedCourseId = null;
        _selectedCourseName = null;
      });
    }
  }

  Future<void> _fetchCoursesByUserId(String userId) async {
    setState(() {
      _isLoadingCourses = true;
      _coursesError = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://bgnuerp.online/api/get_courses?user_id=$userId'),
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData is List) {
          setState(() {
            _courses = responseData;
            if (_courses.isNotEmpty) {
              _selectedCourseId = _courses[0]['id'];
              _selectedCourseName = _courses[0]['subject_name'];
            }
          });
        } else {
          setState(() {
            _coursesError = 'Unexpected API response format';
          });
        }
      } else {
        setState(() {
          _coursesError = 'Failed to fetch courses. Status code: ${response.statusCode}';
        });
      }
    } on TimeoutException {
      setState(() {
        _coursesError = 'Request timed out. Please try again.';
      });
    } catch (error) {
      setState(() {
        _coursesError = 'Error: ${error.toString()}';
      });
    } finally {
      setState(() {
        _isLoadingCourses = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null || _selectedCourseName == null) {
      setState(() {
        _errorMessage = 'Please select a course';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    final queryParams = {
      'user_id': _submitUserIdController.text.trim(),
      'course_name': _selectedCourseName!,
      'semester_no': _semesterNoController.text.trim(),
      'credit_hours': _creditHoursController.text.trim(),
      'marks': _marksController.text.trim(),
    };

    final uri = Uri.https(
      'devtechtop.com',
      '/management/public/api/grades',
      queryParams,
    );

    try {
      final response = await http.get(uri).timeout(Duration(seconds: 15));
      final responseData = json.decode(response.body);

      print("Submit Response: $responseData");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _formKey.currentState!.reset();
        setState(() {
          _successMessage = 'Grade added successfully';
          _selectedCourseId = null;
          _selectedCourseName = null;
        });

        if (_submitUserIdController.text.trim() ==
            _fetchUserIdController.text.trim()) {
          await _fetchGradesByUserId(_fetchUserIdController.text.trim());
        }
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Failed to submit grade';
        });
      }
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Request timed out. Please try again.';
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Error: ${error.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _fetchGradesByUserId(String userId) async {
    if (userId.isEmpty) {
      setState(() {
        _gradesData = [];
        _gradesError = '';
      });
      return;
    }

    setState(() {
      _isFetchingGrades = true;
      _gradesError = '';
    });

    final uri = Uri.parse(
        'https://devtechtop.com/management/public/api/select_data?user_id=$userId');

    try {
      final response = await http.get(uri).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("Raw API Response Structure: ${responseData.runtimeType}");
        print("Raw API Response: $responseData");

        if (responseData is List) {
          // If response is already a list, use it directly
          setState(() {
            _gradesData = responseData.where((grade) =>
            grade['user_id'].toString() == userId.toString()
            ).toList();
          });
        } else if (responseData is Map && responseData.containsKey('data')) {
          // Some APIs wrap the data in a 'data' field
          final dataList = responseData['data'];
          if (dataList is List) {
            setState(() {
              _gradesData = dataList.where((grade) =>
              grade['user_id'].toString() == userId.toString()
              ).toList();
            });
          } else {
            setState(() {
              _gradesData = [];
              _gradesError = 'Unexpected data format from API';
            });
          }
        } else {
          // Handle single object response by wrapping in a list
          setState(() {
            if (responseData['user_id'].toString() == userId.toString()) {
              _gradesData = [responseData];
            } else {
              _gradesData = [];
            }
          });
        }

        // If no grades were found after filtering
        if (_gradesData.isEmpty) {
          setState(() {
            _gradesError = 'No grades found for User ID: $userId';
          });
        }
      } else {
        // Handle error response
        try {
          final errorData = json.decode(response.body);
          setState(() {
            _gradesError = errorData['message'] ?? 'Failed to fetch grades. Status code: ${response.statusCode}';
          });
        } catch (e) {
          setState(() {
            _gradesError = 'Failed to fetch grades. Status code: ${response.statusCode}';
          });
        }
      }
    } on TimeoutException {
      setState(() {
        _gradesError = 'Request timed out. Please try again.';
      });
    } catch (error) {
      setState(() {
        _gradesError = 'Error: ${error.toString()}';
        print("Fetch error: $error");
      });
    } finally {
      setState(() {
        _isFetchingGrades = false;
      });
    }
  }

  String _calculateGrade(dynamic marks) {
    if (marks == null) return 'N/A';

    double score;
    try {
      score = double.parse(marks.toString());
    } catch (e) {
      return 'N/A';
    }

    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  double _calculateGPA(dynamic marks) {
    if (marks == null) return 0.0;

    double score;
    try {
      score = double.parse(marks.toString());
    } catch (e) {
      return 0.0;
    }

    if (score >= 90) return 4.0;
    if (score >= 80) return 3.0;
    if (score >= 70) return 2.0;
    if (score >= 60) return 1.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total GPA if we have grades
    double totalGPA = 0.0;
    int totalCreditHours = 0;

    if (_gradesData.isNotEmpty) {
      double totalPoints = 0.0;

      for (var grade in _gradesData) {
        double creditHours = 0.0;
        try {
          creditHours = double.parse(grade['credit_hours'].toString());
        } catch (e) {
          continue;
        }

        double gpa = _calculateGPA(grade['marks']);
        totalPoints += gpa * creditHours;
        totalCreditHours += creditHours.toInt();
      }

      if (totalCreditHours > 0) {
        totalGPA = totalPoints / totalCreditHours;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Grade Management'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Add Grade Section
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.indigo.shade50],
                      ),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.add_chart, color: Colors.indigo),
                              SizedBox(width: 10),
                              Text(
                                'Add New Grade',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 30, thickness: 1, color: Colors.indigo.shade100),

                          if (_errorMessage.isNotEmpty)
                            _buildMessageCard(_errorMessage, true),
                          if (_successMessage.isNotEmpty)
                            _buildMessageCard(_successMessage, false),

                          _buildTextField(
                            controller: _submitUserIdController,
                            label: 'User ID',
                            hint: 'Enter the student ID',
                            icon: Icons.person,
                            validator: (value) =>
                            value!.isEmpty ? 'Required field' : null,
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 16),

                          // Course Dropdown
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Course',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.indigo.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              _isLoadingCourses
                                  ? Center(child: CircularProgressIndicator())
                                  : _coursesError.isNotEmpty
                                  ? Text(
                                _coursesError,
                                style: TextStyle(color: Colors.red),
                              )
                                  : _courses.isEmpty
                                  ? Text(
                                'Enter User ID to load courses',
                                style: TextStyle(color: Colors.grey),
                              )
                                  : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.indigo.shade300,
                                    width: 1,
                                  ),
                                  color: Colors.white,
                                ),
                                child: DropdownSearch<Map<String, dynamic>>(
                                  items: _courses.cast<Map<String, dynamic>>(),
                                  itemAsString: (course) =>
                                  '${course['subject_code']} - ${course['subject_name']}',
                                  selectedItem: _selectedCourseId == null
                                      ? null
                                      : _courses.firstWhere(
                                          (course) => course['id'] == _selectedCourseId,
                                      orElse: () => {}),
                                  onChanged: (selectedCourse) {
                                    setState(() {
                                      _selectedCourseId = selectedCourse?['id'];
                                      _selectedCourseName = selectedCourse?['subject_name'];
                                    });
                                  },
                                  dropdownDecoratorProps: DropDownDecoratorProps(
                                    dropdownSearchDecoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      border: InputBorder.none,
                                      hintText: "Select a course",
                                      prefixIcon: Icon(Icons.search, color: Colors.indigo),
                                    ),
                                    baseStyle: TextStyle(
                                      fontSize: 16,
                                      color: Colors.indigo.shade800,
                                    ),
                                  ),
                                  popupProps: PopupProps.modalBottomSheet(
                                    showSearchBox: true,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: "Search courses...",
                                        prefixIcon: Icon(Icons.search),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color: Colors.indigo.shade300,
                                          ),
                                        ),
                                      ),
                                    ),
                                    modalBottomSheetProps: ModalBottomSheetProps(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                    ),
                                    itemBuilder: (context, item, isSelected) {
                                      return ListTile(
                                        title: Text(
                                          '${item['subject_code']} - ${item['subject_name']}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.indigo.shade800,
                                          ),
                                        ),
                                        trailing: isSelected
                                            ? Icon(Icons.check_circle,
                                            color: Colors.indigo)
                                            : null,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          _buildTextField(
                            controller: _semesterNoController,
                            label: 'Semester Number',
                            hint: 'Enter semester number',
                            icon: Icons.calendar_today,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value!.isEmpty) return 'Required field';
                              if (int.tryParse(value) == null)
                                return 'Enter valid number';
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: _creditHoursController,
                            label: 'Credit Hours',
                            hint: 'Enter credit hours',
                            icon: Icons.timer,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value!.isEmpty) return 'Required field';
                              if (double.tryParse(value) == null)
                                return 'Enter valid number';
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          _buildTextField(
                            controller: _marksController,
                            label: 'Marks',
                            hint: 'Enter marks (0-100)',
                            icon: Icons.score,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value!.isEmpty) return 'Required field';
                              final marks = double.tryParse(value);
                              if (marks == null) return 'Enter valid number';
                              if (marks < 0 || marks > 100)
                                return 'Must be 0-100';
                              return null;
                            },
                          ),
                          SizedBox(height: 24),
                          _isLoading
                              ? Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.indigo),
                              ))
                              : _buildGradientButton(
                            'SUBMIT GRADE',
                            Icons.check_circle,
                            _submitForm,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Fetch Grades Section
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.indigo.shade50],
                      ),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.search, color: Colors.indigo),
                            SizedBox(width: 10),
                            Text(
                              'Fetch Grades by User ID',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 30, thickness: 1, color: Colors.indigo.shade100),
                        _buildTextField(
                          controller: _fetchUserIdController,
                          label: 'User ID',
                          hint: 'Enter user ID to fetch grades',
                          icon: Icons.person_search,
                          validator: null,
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 16),
                        _buildGradientButton(
                          'FETCH GRADES',
                          Icons.search,
                              () => _fetchGradesByUserId(_fetchUserIdController.text.trim()),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Display Grades
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.indigo.shade50],
                      ),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.grade, color: Colors.indigo),
                                SizedBox(width: 10),
                                Text(
                                  _fetchUserIdController.text.trim().isEmpty
                                      ? 'Grades'
                                      : 'Grades for Student #${_fetchUserIdController.text.trim()}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh, color: Colors.indigo),
                              onPressed: () => _fetchGradesByUserId(
                                  _fetchUserIdController.text.trim()),
                            ),
                          ],
                        ),
                        Divider(height: 30, thickness: 1, color: Colors.indigo.shade100),

                        if (_gradesData.isNotEmpty)
                          Container(
                            padding: EdgeInsets.all(15),
                            margin: EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.indigo.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Summary',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.indigo,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildSummaryItem(
                                        'Courses',
                                        _gradesData.length.toString(),
                                        Icons.book
                                    ),
                                    _buildSummaryItem(
                                        'Credit Hours',
                                        totalCreditHours.toString(),
                                        Icons.timer
                                    ),
                                    _buildSummaryItem(
                                        'GPA',
                                        totalGPA.toStringAsFixed(2),
                                        Icons.auto_graph
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        _isFetchingGrades
                            ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                            ))
                            : _gradesError.isNotEmpty
                            ? _buildMessageCard(_gradesError, true)
                            : _gradesData.isEmpty
                            ? Container(
                          padding: EdgeInsets.all(30),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                _fetchUserIdController.text.trim().isEmpty
                                    ? 'Enter a User ID to view grades'
                                    : 'No grades found for this user',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _gradesData.length,
                          itemBuilder: (context, index) {
                            final grade = _gradesData[index];
                            final letterGrade = _calculateGrade(grade['marks']);
                            final gpa = _calculateGPA(grade['marks']);

                            // Determine color based on grade
                            Color gradeColor;
                            if (letterGrade == 'A') gradeColor = Colors.green;
                            else if (letterGrade == 'B') gradeColor = Colors.blue;
                            else if (letterGrade == 'C') gradeColor = Colors.orange;
                            else if (letterGrade == 'D') gradeColor = Colors.deepOrange;
                            else gradeColor = Colors.red;

                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.white, Colors.indigo.shade50],
                                  ),
                                ),
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            grade['course_name'] ?? 'No Course Name',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.indigo.shade800,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: gradeColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: gradeColor),
                                          ),
                                          child: Text(
                                            letterGrade,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: gradeColor,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Divider(
                                      thickness: 1,
                                      color: Colors.indigo.shade100,
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildGradeDetailItem(
                                          'Semester',
                                          grade['semester_no'] ?? 'N/A',
                                          Icons.calendar_today,
                                        ),
                                        _buildGradeDetailItem(
                                          'Credits',
                                          grade['credit_hours'] ?? 'N/A',
                                          Icons.timer,
                                        ),
                                        _buildGradeDetailItem(
                                          'Marks',
                                          grade['marks'] ?? 'N/A',
                                          Icons.score,
                                        ),
                                        _buildGradeDetailItem(
                                          'GPA',
                                          gpa.toStringAsFixed(1),
                                          Icons.auto_graph,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.indigo),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.indigo),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.indigo, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.indigo.shade200),
        ),
        fillColor: Colors.white,
        filled: true,
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildMessageCard(String message, bool isError) {
    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError ? Colors.red : Colors.green,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.red : Colors.green,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.red.shade800 : Colors.green.shade800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.indigoAccent],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildGradeDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.indigo,
            size: 20,
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.indigo.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.indigo),
          SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.indigo.shade800,
            ),
          ),
        ],
      ),
    );
  }
}