import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'student_marks_v2.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE students(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            rollNo TEXT NOT NULL,
            className TEXT NOT NULL,
            semester TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE marks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            studentId INTEGER NOT NULL,
            studentName TEXT NOT NULL,
            rollNo TEXT NOT NULL,
            subject TEXT NOT NULL,
            marksObtained REAL NOT NULL,
            totalMarks REAL NOT NULL,
            FOREIGN KEY (studentId) REFERENCES students(id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE students ADD COLUMN rollNo TEXT NOT NULL DEFAULT ""');
          await db.execute('ALTER TABLE marks ADD COLUMN rollNo TEXT NOT NULL DEFAULT ""');
        }
      },
    );
  }

  // Student methods
  Future<int> insertStudent(Map<String, dynamic> student) async {
    final db = await database;
    return await db.insert('students', student);
  }

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final db = await database;
    return await db.query('students');
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    await db.delete('marks', where: 'studentId = ?', whereArgs: [id]);
    return await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }


  // Marks methods
  Future<int> insertMark(Map<String, dynamic> mark) async {
    final db = await database;
    return await db.insert('marks', mark);
  }

  Future<List<Map<String, dynamic>>> getMarksForStudent(int studentId) async {
    final db = await database;
    return await db.query(
      'marks',
      where: 'studentId = ?',
      whereArgs: [studentId],
    );
  }

  Future<int> deleteMark(int id) async {
    final db = await database;
    return await db.delete('marks', where: 'id = ?', whereArgs: [id]);
  }

  // Add this method to your DatabaseHelper class
  Future<int> updateMark(Map<String, dynamic> mark) async {
    final db = await database;
    return await db.update(
      'marks',
      mark,
      where: 'id = ?',
      whereArgs: [mark['id']],
    );
  }

  Future<double> calculateOverallPercentage(int studentId) async {
    final marks = await getMarksForStudent(studentId);
    if (marks.isEmpty) return 0.0;

    double totalObtained = 0;
    double totalPossible = 0;

    for (var mark in marks) {
      totalObtained += mark['marksObtained'] as double;
      totalPossible += mark['totalMarks'] as double;
    }

    return (totalObtained / totalPossible) * 100;
  }

  // New GPA calculation methods
  double _calculateGPA(double percentage) {
    if (percentage >= 80) return 4.0; // A
    if (percentage >= 70) return 3.0; // B
    if (percentage >= 60) return 2.0; // C
    if (percentage >= 50) return 1.0; // D
    return 0.0; // F
  }

  Future<Map<String, double>> getSubjectGPAs(int studentId) async {
    final marks = await getMarksForStudent(studentId);
    final Map<String, double> subjectGPAs = {};

    for (var mark in marks) {
      final subject = mark['subject'] as String;
      final obtained = mark['marksObtained'] as double;
      final total = mark['totalMarks'] as double;
      final percentage = (obtained / total) * 100;
      subjectGPAs[subject] = _calculateGPA(percentage);
    }

    return subjectGPAs;
  }

  Future<double> calculateOverallGPA(int studentId) async {
    final subjectGPAs = await getSubjectGPAs(studentId);
    if (subjectGPAs.isEmpty) return 0.0;

    double totalGPA = 0.0;
    subjectGPAs.forEach((subject, gpa) {
      totalGPA += gpa;
    });

    return totalGPA / subjectGPAs.length;
  }
}