import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'grades.db');

    return _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE grades(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT,
            courseName TEXT,
            semesterNo TEXT,
            creditHours TEXT,
            marks TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertGrade(Map<String, String> gradeData) async {
    final db = await getDatabase();
    await db.insert('grades', gradeData);
  }

  static Future<List<Map<String, dynamic>>> fetchGrades() async {
    final db = await getDatabase();
    return await db.query('grades');
  }
}
