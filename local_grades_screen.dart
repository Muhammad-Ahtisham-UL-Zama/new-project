import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'db_helper.dart';

class LocalGradesScreen extends StatefulWidget {
  @override
  _LocalGradesScreenState createState() => _LocalGradesScreenState();
}

class _LocalGradesScreenState extends State<LocalGradesScreen> {
  List<Map<String, dynamic>> _grades = [];

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    final data = await DBHelper.fetchGrades();
    setState(() {
      _grades = data;
    });
  }

  Future<void> _sendGradeToServer(Map<String, dynamic> grade) async {
    final uri = Uri.https(
      'devtechtop.com',
      '/management/public/api/grades',
      {
        'user_id': grade['userId'],
        'course_name': grade['courseName'],
        'semester_no': grade['semesterNo'],
        'credit_hours': grade['creditHours'],
        'marks': grade['marks'],
      },
    );

    try {
      final response = await http.get(uri).timeout(Duration(seconds: 15));
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sent grade for ${grade['courseName']}')),
        );
      } else {
        throw Exception(responseData['message'] ?? 'Unknown error');
      }
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request timed out.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Local Grades')),
      body: _grades.isEmpty
          ? Center(child: Text('No grades saved locally.'))
          : ListView.builder(
        itemCount: _grades.length,
        itemBuilder: (context, index) {
          final grade = _grades[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text('${grade['courseName']} (${grade['marks']} marks)'),
              subtitle: Text('User ID: ${grade['userId']} | Semester: ${grade['semesterNo']}'),
              trailing: IconButton(
                icon: Icon(Icons.send, color: Colors.indigo),
                onPressed: () => _sendGradeToServer(grade),
              ),
            ),
          );
        },
      ),
    );
  }
}
