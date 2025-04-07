import 'package:flutter/material.dart';
import 'database_helper_api.dart';
import 'api_service.dart';

class StudentResultsPage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialData;

  const StudentResultsPage({Key? key, this.initialData}) : super(key: key);
  @override
  _StudentResultsPageState createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends State<StudentResultsPage> {
  List<Map<String, dynamic>> _studentResults = [];
  List<String> _semesters = [];
  bool _isLoading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      // Use the passed-in data initially
      _studentResults = widget.initialData!;
      _loadDistinctSemesters(); // Just load semesters
    }
    _loadLocalData();
  }

  Future<void> _loadDistinctSemesters() async {
    _semesters = _studentResults
        .map((r) => r['mysemester'].toString())
        .toSet()
        .toList()
      ..sort();
    setState(() {});
  }

  Future<void> _loadLocalData() async {
    setState(() => _isLoading = true);
    try {
      _studentResults = await _dbHelper.getAllStudentResults();
      _semesters = await _dbHelper.getDistinctSemesters();
    } catch (e) {
      _showSnackBar('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAndStoreResults() async {
    setState(() => _isLoading = true);
    try {
      await _dbHelper.deleteAllResults();
      final apiData = await ApiService.fetchStudentResults();
      for (var result in apiData) {
        await _dbHelper.insertStudentResult(result);
      }
      await _loadLocalData();
      _showSnackBar('Data refreshed successfully!');
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteResult(int id) async {
    final confirmed = await _showConfirmationDialog(
        'Delete Result', 'Are you sure you want to delete this result?');
    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await _dbHelper.deleteResult(id);
        await _loadLocalData();
        _showSnackBar('Result deleted!');
      } catch (e) {
        _showSnackBar('Error deleting: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAllResults() async {
    final confirmed = await _showConfirmationDialog(
        'Delete All Results', 'Are you sure you want to delete all results?');
    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await _dbHelper.deleteAllResults();
        await _loadLocalData();
        _showSnackBar('All results deleted!');
      } catch (e) {
        _showSnackBar('Error deleting all: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.9),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirm'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    ) ??
        false;
  }

  double _calculateGPA(double marks) {
    if (marks >= 90) return 4.0;
    if (marks >= 85) return 3.7;
    if (marks >= 80) return 3.3;
    if (marks >= 75) return 3.0;
    if (marks >= 70) return 2.7;
    if (marks >= 65) return 2.3;
    if (marks >= 60) return 2.0;
    if (marks >= 55) return 1.7;
    if (marks >= 50) return 1.3;
    return 0.0;
  }

  String _calculateGrade(double marks) {
    if (marks >= 80) return 'A';
    if (marks >= 65) return 'B';
    if (marks >= 50) return 'C';
    return 'F';
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green.shade700;
      case 'B':
        return Colors.blue.shade700;
      case 'C':
        return Colors.orange.shade700;
      case 'F':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildSemesterTable(String semester) {
    final semesterResults = _studentResults
        .where((result) => result['mysemester'] == semester)
        .toList();

    if (semesterResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text('No results for Semester $semester'),
            ],
          ),
        ),
      );
    }

    double totalCreditHours = 0;
    double totalWeightedGPA = 0;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    return Theme.of(context).primaryColor.withOpacity(0.1);
                  }),
              dataRowMaxHeight: 60,
              horizontalMargin: 16,
              columnSpacing: 16,
              columns: const [
                DataColumn(
                  label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold)),
                  tooltip: 'Course Code',
                ),
                DataColumn(
                  label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
                  tooltip: 'Course Title',
                ),
                DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Obtained', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Credits', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('GPA', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: semesterResults.map((result) {
                final marks = double.tryParse(result['obtainedmarks']?.toString() ?? '0') ?? 0;
                String grade = result['grade'];
                double gpa = 0.0;
                final creditHours = double.tryParse(result['credithours']?.toString() ?? '0') ?? 0;

                if (marks == 0 && result['consider_status'] == 'NA') {
                  grade = 'NA';
                } else if (result['consider_status'] != 'NA') {
                  grade = _calculateGrade(marks);
                  gpa = _calculateGPA(marks);
                  totalCreditHours += creditHours;
                  totalWeightedGPA += gpa * creditHours;
                }

                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        constraints: BoxConstraints(maxWidth: 80),
                        child: Text(
                          result['coursecode'] ?? '',
                          style: TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: BoxConstraints(maxWidth: 200),
                        child: Text(
                          result['coursetitle'] ?? '',
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Center(child: Text(result['totalmarks']?.toString() ?? ''))),
                    DataCell(Center(child: Text(result['obtainedmarks']?.toString() ?? ''))),
                    DataCell(Center(child: Text(creditHours.toString()))),
                    DataCell(Center(child: Text(gpa.toStringAsFixed(2)))),
                    DataCell(
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getGradeColor(grade).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          grade,
                          style: TextStyle(
                            color: _getGradeColor(grade),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(result['consider_status'] ?? '')),
                    DataCell(
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteResult(result['id']),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Semester GPA:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    (totalCreditHours > 0 ? totalWeightedGPA / totalCreditHours : 0).toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    if (_studentResults.isEmpty) return Container();

    final student = _studentResults.first;
    final studentName = student['studentname'] ?? 'NA';
    final progName = student['progname'] ?? 'NA';
    final shift = student['shift'] ?? 'NA';
    final rollNo = student['rollno'] ?? 'NA';

    double totalCreditHours = 0;
    double totalWeightedGPA = 0;
    int validCourseCount = 0;

    for (var result in _studentResults) {
      if (result['consider_status'] != 'NA') {
        final marks = double.tryParse(result['obtainedmarks']?.toString() ?? '0') ?? 0;
        final gpa = _calculateGPA(marks);
        final creditHours = double.tryParse(result['credithours']?.toString() ?? '0') ?? 0;

        totalCreditHours += creditHours;
        totalWeightedGPA += gpa * creditHours;
        validCourseCount++;
      }
    }

    final cgpa = validCourseCount > 0 ? totalWeightedGPA / totalCreditHours : 0;
    final statusColor = cgpa >= 3.0
        ? Colors.green
        : cgpa >= 2.0
        ? Colors.orange
        : Colors.red;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Roll No: $rollNo',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _infoItem(
                      'Program',
                      progName,
                      Icons.school,
                    ),
                  ),
                  Expanded(
                    child: _infoItem(
                      'Shift',
                      shift,
                      Icons.access_time,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'CGPA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: statusColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        cgpa.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Academic Record',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchAndStoreResults,
            tooltip: 'Refresh & Restore Data',
          ),
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: _deleteAllResults,
            tooltip: 'Delete All Results',
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
        ),
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading data...'),
            ],
          ),
        )
            : _studentResults.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'No results found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap refresh to load data from server',
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _fetchAndStoreResults,
                icon: Icon(Icons.refresh),
                label: Text('Refresh Now'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          child: Column(
            children: [
              _buildSummary(),
              ..._semesters.map((semester) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).primaryColor,
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Semester $semester',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildSemesterTable(semester),
                  ],
                );
              }).toList(),
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}