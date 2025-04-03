import 'package:flutter/material.dart';
import 'database_helper_api.dart';
import 'api_service.dart';

class StudentResultsPage extends StatefulWidget {
  @override
  _StudentResultsPageState createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends State<StudentResultsPage> {
  List<Map<String, dynamic>> _studentResults = [];
  List<String> _semesters = [];
  String? _selectedSemester;
  bool _isLoading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedSemester != null) {
        _studentResults = await _dbHelper.getResultsBySemester(_selectedSemester!);
      } else {
        _studentResults = await _dbHelper.getAllStudentResults();
      }

      // Load available semesters for filtering
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
      // First restore all results
      await _dbHelper.restoreAllResults();

      // Then fetch new data
      final apiData = await ApiService.fetchStudentResults();

      for (var result in apiData) {
        await _dbHelper.insertStudentResult(result);
      }

      await _loadLocalData();
      _showSnackBar('Data refreshed and all results restored!');
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteResult(int id) async {
    final confirmed = await _showConfirmationDialog(
      'Delete Result',
      'Are you sure you want to delete this result?',
    );

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
      'Delete All Results',
      'Are you sure you want to delete all results?',
    );

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final marks = result['obtainedmarks']?.toString() ?? '';
    final marksDisplay = marks.isEmpty ? "N/A" : marks;

    // Determine grade color based on marks
    Color gradeColor = Colors.green;
    if (double.tryParse(marks) != null) {
      double numMarks = double.parse(marks);
      if (numMarks < 50) gradeColor = Colors.red;
      else if (numMarks < 70) gradeColor = Colors.orange;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${result['coursecode']} - ${result['coursetitle']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteResult(result['id']),
                ),
              ],
            ),
            Divider(height: 16, thickness: 1),

            // Student info section
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Student', result['studentname']),
                  SizedBox(height: 4),
                  _infoRow('Father', result['fathername']),
                  SizedBox(height: 4),
                  _infoRow('Program', '${result['progname']} (${result['shift']})'),
                  SizedBox(height: 4),
                  _infoRow('Roll No', result['rollno']),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Results section
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Credit Hours', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        Text('${result['credithours']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: gradeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gradeColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Marks', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        Text(marksDisplay, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: gradeColor)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Footer row with semester and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text('Semester ${result['mysemester']}'),
                  backgroundColor: Colors.blue[100],
                  labelStyle: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
                  padding: EdgeInsets.symmetric(horizontal: 8),
                ),
                Chip(
                  label: Text(
                    result['consider_status'] == 'E' ? 'Enrolled' : result['consider_status'],
                    style: TextStyle(
                      color: result['consider_status'] == 'E' ? Colors.green[800] : Colors.orange[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: result['consider_status'] == 'E' ? Colors.green[50] : Colors.orange[50],
                  padding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Group results by semester
  Map<String, List<Map<String, dynamic>>> _groupBySemester() {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (var result in _studentResults) {
      final semester = result['mysemester']?.toString() ?? 'Unknown';
      if (!grouped.containsKey(semester)) {
        grouped[semester] = [];
      }
      grouped[semester]!.add(result);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedResults = _groupBySemester();
    final sortedSemesters = groupedResults.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Student Results',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        actions: [
          // Improved semester filter dropdown
          if (_semesters.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedSemester,
                  hint: Text(
                    'Filter Semester',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  dropdownColor: Theme.of(context).primaryColor,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  icon: Icon(Icons.filter_list, color: Colors.white, size: 20),
                  isDense: true,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSemester = newValue;
                    });
                    _loadLocalData();
                  },
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Semesters'),
                    ),
                    ..._semesters.map((semester) {
                      return DropdownMenuItem<String?>(
                        value: semester,
                        child: Text('Semester $semester'),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

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
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _studentResults.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Tap refresh to load data from server'),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAndStoreResults,
              icon: Icon(Icons.refresh),
              label: Text('Refresh Now'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchAndStoreResults,
        child: _selectedSemester == null
            ? ListView(
          children: sortedSemesters.map((semester) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Semester $semester',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '(${groupedResults[semester]!.length} courses)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Expanded(child: Divider(indent: 16)),
                    ],
                  ),
                ),
                ...groupedResults[semester]!.map((result) => _buildResultCard(result)).toList(),
              ],
            );
          }).toList(),
        )
            : ListView.builder(
          itemCount: _studentResults.length,
          itemBuilder: (context, index) {
            return _buildResultCard(_studentResults[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchAndStoreResults,
        child: Icon(Icons.refresh),
        backgroundColor: Theme.of(context).primaryColor,
        tooltip: 'Refresh & Restore Data',
      ),
    );
  }
}