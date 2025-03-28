import 'package:flutter/material.dart';
import 'database_helper_marks.dart';

class MarksPage extends StatefulWidget {
  final int studentId;
  final String studentName;
  final String rollNo;

  const MarksPage({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.rollNo,
  }) : super(key: key);

  @override
  State<MarksPage> createState() => _MarksPageState();
}

class _MarksPageState extends State<MarksPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _marksObtainedController = TextEditingController();
  final TextEditingController _totalMarksController = TextEditingController();

  List<Map<String, dynamic>> _marks = [];
  double _totalObtainedMarks = 0;
  double _totalPossibleMarks = 0;
  double _overallPercentage = 0;
  double _overallGPA = 0;
  Map<String, double> _subjectGPAs = {};
  int? _editingMarkId;

  @override
  void initState() {
    super.initState();
    _refreshMarks();
  }

  Future<void> _refreshMarks() async {
    final marks = await _dbHelper.getMarksForStudent(widget.studentId);

    double totalObtained = 0;
    double totalPossible = 0;
    Map<String, double> subjectGPAs = {};

    for (var mark in marks) {
      final obtained = mark['marksObtained'] as double;
      final total = mark['totalMarks'] as double;
      totalObtained += obtained;
      totalPossible += total;

      final percentage = (obtained / total) * 100;
      subjectGPAs[mark['subject']] = _calculateGPA(percentage);
    }

    double overallGPA = subjectGPAs.values.isEmpty
        ? 0
        : subjectGPAs.values.reduce((a, b) => a + b) / subjectGPAs.length;

    setState(() {
      _marks = marks;
      _totalObtainedMarks = totalObtained;
      _totalPossibleMarks = totalPossible;
      _overallPercentage = totalPossible > 0 ? (totalObtained / totalPossible) * 100 : 0;
      _overallGPA = overallGPA;
      _subjectGPAs = subjectGPAs;
    });
  }

  double _calculateGPA(double percentage) {
    if (percentage >= 80) return 4.0;
    if (percentage >= 70) return 3.0;
    if (percentage >= 60) return 2.0;
    if (percentage >= 50) return 1.0;
    return 0.0;
  }

  String _formatMarks(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
  }

  Future<void> _saveMark() async {
    if (_formKey.currentState!.validate()) {
      final markData = {
        'studentId': widget.studentId,
        'studentName': widget.studentName,
        'rollNo': widget.rollNo,
        'subject': _subjectController.text,
        'marksObtained': double.parse(_marksObtainedController.text),
        'totalMarks': double.parse(_totalMarksController.text),
      };

      if (_editingMarkId != null) {
        await _dbHelper.updateMark({
          ...markData,
          'id': _editingMarkId,
        });
      } else {
        await _dbHelper.insertMark(markData);
      }

      _refreshMarks();
      _clearForm();
    }
  }

  void _editMark(Map<String, dynamic> mark) {
    setState(() {
      _editingMarkId = mark['id'] as int;
      _subjectController.text = mark['subject'] as String;
      _marksObtainedController.text = _formatMarks(mark['marksObtained'] as double);
      _totalMarksController.text = _formatMarks(mark['totalMarks'] as double);
    });
  }

  Future<void> _deleteMark(int id) async {
    await _dbHelper.deleteMark(id);
    _refreshMarks();
  }

  void _clearForm() {
    setState(() {
      _editingMarkId = null;
    });
    _formKey.currentState?.reset();
    _subjectController.clear();
    _marksObtainedController.clear();
    _totalMarksController.clear();
  }

  Color _getPerformanceColor() {
    if (_overallPercentage >= 80) return Colors.green.shade700;
    if (_overallPercentage >= 60) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          '${widget.studentName} (${widget.rollNo})',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          if (_editingMarkId != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _clearForm,
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    // Performance Summary Card
                    Card(
                      margin: const EdgeInsets.all(16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'PERFORMANCE SUMMARY',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSummaryTile(
                                  icon: Icons.assessment,
                                  title: 'Total Marks',
                                  value: '${_formatMarks(_totalObtainedMarks)}/${_formatMarks(_totalPossibleMarks)}',
                                ),
                                _buildSummaryTile(
                                  icon: Icons.percent,
                                  title: 'Percentage',
                                  value: '${_overallPercentage.toStringAsFixed(1)}%',
                                  color: _getPerformanceColor(),
                                ),
                                _buildSummaryTile(
                                  icon: Icons.star,
                                  title: 'Overall GPA',
                                  value: _overallGPA.toStringAsFixed(2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Add Marks Form
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _subjectController,
                                  decoration: InputDecoration(
                                    labelText: 'Subject',
                                    prefixIcon: const Icon(Icons.book, color: Colors.indigo),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.indigo.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.indigo.shade500),
                                    ),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                                  scrollPadding: const EdgeInsets.only(bottom: 100),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _marksObtainedController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Marks Obtained',
                                          prefixIcon: const Icon(Icons.trending_up, color: Colors.indigo),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.indigo.shade300),
                                          ),
                                        ),
                                        validator: (value) => value?.isEmpty ?? true
                                            ? 'Required'
                                            : double.tryParse(value!) == null
                                            ? 'Invalid number'
                                            : null,
                                        scrollPadding: const EdgeInsets.only(bottom: 100),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _totalMarksController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Total Marks',
                                          prefixIcon: const Icon(Icons.library_books, color: Colors.indigo),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.indigo.shade300),
                                          ),
                                        ),
                                        validator: (value) => value?.isEmpty ?? true
                                            ? 'Required'
                                            : double.tryParse(value!) == null
                                            ? 'Invalid number'
                                            : null,
                                        scrollPadding: const EdgeInsets.only(bottom: 100),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _saveMark,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: Text(
                                      _editingMarkId != null ? 'UPDATE MARKS' : 'ADD MARKS',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Marks Table
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * 0.5,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                headingRowColor: MaterialStateColor.resolveWith(
                                      (states) => Colors.indigo.shade50,
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Subject',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Marks',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Percentage',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'GPA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Actions',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: _marks.map((mark) {
                                  final obtained = mark['marksObtained'] as double;
                                  final total = mark['totalMarks'] as double;
                                  final percentage = (obtained / total) * 100;
                                  final gpa = _subjectGPAs[mark['subject']] ?? 0.0;
                                  final percentageColor = percentage >= 80
                                      ? Colors.green.shade700
                                      : percentage >= 60
                                      ? Colors.orange.shade700
                                      : Colors.red.shade700;
                                  final gpaColor = gpa >= 3.0
                                      ? Colors.green.shade700
                                      : gpa >= 2.0
                                      ? Colors.orange.shade700
                                      : Colors.red.shade700;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          mark['subject'],
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${_formatMarks(obtained)}/${_formatMarks(total)}',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${percentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            color: percentageColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          gpa.toStringAsFixed(2),
                                          style: TextStyle(
                                            color: gpaColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit, color: Colors.blue.shade700),
                                              onPressed: () => _editMark(mark),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Colors.red.shade700),
                                              onPressed: () => _deleteMark(mark['id'] as int),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required String title,
    required String value,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.indigo),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.indigo[800],
          ),
        ),
      ],
    );
  }
}