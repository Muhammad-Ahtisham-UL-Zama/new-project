import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    print("Initializing database...");
    _database = await _initDB('student_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    print("Database path: $path");

    return await openDatabase(
      path,
      version: 3, // Increment version to trigger onUpgrade
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _verifyTableStructure(db);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    print("Creating new database tables...");
    await db.execute('''
  CREATE TABLE student_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    studentname TEXT NOT NULL,
    fathername TEXT NOT NULL,
    progname TEXT NOT NULL,
    shift TEXT NOT NULL,
    rollno TEXT NOT NULL,
    coursecode TEXT NOT NULL,
    coursetitle TEXT NOT NULL,
    credithours REAL NOT NULL,
    obtainedmarks TEXT NOT NULL,
    mysemester TEXT NOT NULL,
    consider_status TEXT NOT NULL,
    is_deleted INTEGER DEFAULT 0,
    totalmarks INTEGER DEFAULT 100,
    grade TEXT DEFAULT 'F',
    UNIQUE(rollno, coursecode, mysemester)
  )
  ''');
    print("student_results table created successfully");
  }

  // Handle database version upgrades
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from version $oldVersion to $newVersion");

    if (oldVersion < 2) {
      await db.execute("DROP TABLE IF EXISTS student_results");
      await _createDB(db, newVersion);
    }
    if (oldVersion < 3){
      await db.execute('ALTER TABLE student_results ADD COLUMN totalmarks INTEGER DEFAULT 100');
      await db.execute('ALTER TABLE student_results ADD COLUMN grade TEXT DEFAULT \'F\'');
    }
  }

  Future<void> _verifyTableStructure(Database db) async {
    print("Verifying table structure...");
    try {
      final tableInfo = await db.rawQuery("PRAGMA table_info(student_results)");

      final requiredColumns = [
        'studentname', 'fathername', 'progname', 'shift', 'rollno',
        'coursecode', 'coursetitle', 'credithours', 'obtainedmarks',
        'mysemester', 'consider_status', 'is_deleted', 'totalmarks','grade'
      ];

      for (final column in requiredColumns) {
        if (!tableInfo.any((col) => col['name'] == column)) {
          throw Exception("Missing column: $column");
        }
      }

      print("Table structure verified successfully");
    } catch (e) {
      print("Table structure verification failed: $e");
      await _rebuildDatabase();
    }
  }

  Future<void> _rebuildDatabase() async {
    print("Rebuilding database...");
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'student_database.db');

    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      await deleteDatabase(path);
      print("Old database deleted successfully");

      _database = await _initDB('student_database.db');
      print("Database rebuilt successfully");
    } catch (e) {
      print("Error rebuilding database: $e");
      rethrow;
    }
  }

  Future<int> insertStudentResult(Map<String, dynamic> result) async {
    print('Inserting record: ${result['coursecode']} - ${result['coursetitle']}');

    if (result['coursecode'] == null || result['coursetitle'] == null) {
      throw Exception("Missing required fields (coursecode or coursetitle)");
    }

    final db = await instance.database;
    final marks = _validateMarks(result['obtainedmarks']);
    String grade;

    if (result['consider_status'] == 'NA') {
      grade = 'NA';
    } else {
      grade = _calculateGrade(marks);
    }

    final data = {
      'studentname': _validateString(result['studentname'], 'studentname'),
      'fathername': _validateString(result['fathername'], 'fathername'),
      'progname': _validateString(result['progname'], 'progname'),
      'shift': _validateString(result['shift'], 'shift'),
      'rollno': _validateString(result['rollno'], 'rollno'),
      'coursecode': _validateString(result['coursecode'], 'coursecode'),
      'coursetitle': _validateString(result['coursetitle'], 'coursetitle'),
      'credithours': _validateCreditHours(result['credithours']),
      'obtainedmarks': marks.toString(),
      'mysemester': _validateString(result['mysemester'], 'mysemester'),
      'consider_status': _validateString(result['consider_status'], 'consider_status'),
      'is_deleted': 0,
      'totalmarks': 100,
      'grade': grade,
    };

    try {
      final id = await db.insert(
          'student_results',
          data,
          conflictAlgorithm: ConflictAlgorithm.replace
      );
      print('Successfully inserted/updated record ID: $id');
      return id;
    } catch (e) {
      print("Error inserting data for ${result['coursecode']}: $e");
      print("Full data being inserted: $data");
      rethrow;
    }
  }

  Future<void> refreshStudentResults(List<Map<String, dynamic>> newResults) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      await txn.update('student_results', {'is_deleted': 1});

      for (final result in newResults) {
        final marks = _validateMarks(result['obtainedmarks']);
        String grade;

        print("Processing course: ${result['coursecode']}, consider_status: ${result['consider_status']}");

        if (result['consider_status'] == 'NA') {
          grade = 'NA';
          print("Setting grade to NA for ${result['coursecode']}");
        } else {
          grade = _calculateGrade(marks);
          print("Calculated grade $grade for ${result['coursecode']} with marks $marks");
        }

        try {
          await txn.insert(
              'student_results',
              {
                'studentname': _validateString(result['studentname'], 'studentname'),
                'fathername': _validateString(result['fathername'], 'fathername'),
                'progname': _validateString(result['progname'], 'progname'),
                'shift': _validateString(result['shift'], 'shift'),
                'rollno': _validateString(result['rollno'], 'rollno'),
                'coursecode': _validateString(result['coursecode'], 'coursecode'),
                'coursetitle': _validateString(result['coursetitle'], 'coursetitle'),
                'credithours': _validateCreditHours(result['credithours']),
                'obtainedmarks': marks.toString(),
                'mysemester': _validateString(result['mysemester'], 'mysemester'),
                'consider_status': _validateString(result['consider_status'], 'consider_status'),
                'is_deleted': 0,
                'totalmarks': 100,
                'grade': grade,
              },
              conflictAlgorithm: ConflictAlgorithm.replace
          );
        } catch (e) {
          print("Error in transaction for ${result['coursecode']}: $e");
        }
      }
    });

    print("Database refreshed with ${newResults.length} records");
  }

  String _validateString(dynamic value, String fieldName) {
    if (value == null) {
      print("Warning: $fieldName is null, converting to empty string");
      return '';
    }
    return value.toString();
  }

  double _validateCreditHours(dynamic value) {
    try {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();

      final strValue = value.toString();
      return double.tryParse(strValue) ?? 0.0;
    } catch (e) {
      print("Error parsing credit hours: $value, using 0.0 instead");
      return 0.0;
    }
  }

  double _validateMarks(dynamic value) {
    try {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();

      final strValue = value.toString();
      return double.tryParse(strValue) ?? 0.0;
    } catch (e) {
      print("Error parsing marks: $value, using 0.0 instead");
      return 0.0;
    }
  }

  String _calculateGrade(double marks) {
    if (marks >= 80) return 'A';
    if (marks >= 65) return 'B';
    if (marks >= 50) return 'C';
    return 'F';
  }

  Future<List<Map<String, dynamic>>> getAllStudentResults() async {
    final db = await instance.database;
    print("Fetching all student results...");

    final results = await db.query(
      'student_results',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'mysemester ASC, coursecode ASC',
    );

    print("Found ${results.length} records");
    return results;
  }

  Future<List<Map<String, dynamic>>> getResultsBySemester(String semester) async {
    final db = await instance.database;
    print("Fetching results for semester: $semester");

    final results = await db.query(
      'student_results',
      where: 'mysemester = ? AND is_deleted = ?',
      whereArgs: [semester, 0],
      orderBy: 'coursecode ASC',
    );

    print("Found ${results.length} records for semester $semester");
    return results;
  }

  Future<List<String>> getDistinctSemesters() async {
    final db = await instance.database;
    print("Fetching distinct semesters...");

    final results = await db.rawQuery(
        'SELECT DISTINCT mysemester FROM student_results WHERE is_deleted = 0 ORDER BY mysemester ASC'
    );

    final semesters = results.map((result) => result['mysemester'] as String).toList();
    print("Found ${semesters.length} distinct semesters: $semesters");
    return semesters;
  }

  Future<int> deleteResult(int id) async {
    final db = await instance.database;
    print("Soft-deleting record ID: $id");

    final count = await db.update(
      'student_results',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );

    print("Deleted $count record(s)");
    return count;
  }

  Future<void> deleteAllResults() async {
    final db = await database;
    await db.delete('student_results'); // Delete all rows
  }

  Future<int> restoreAllResults() async {
    final db = await instance.database;
    print("Restoring all soft-deleted records...");

    final count = await db.update(
      'student_results',
      {'is_deleted': 0},
    );

    print("Restored $count records");
    return count;
  }

  Future<void> debugPrintAllRecords() async {
    final db = await instance.database;
    print("Debug: Printing all records in database...");

    final results = await db.rawQuery('SELECT * FROM student_results');
    print('Total records in database: ${results.length}');

    for (final record in results) {
      print('''
      Record ID: ${record['id']}
      Student: ${record['studentname']} (${record['rollno']})
      Course: ${record['coursecode']} - ${record['coursetitle']}
      Semester: ${record['mysemester']}
      Marks: ${record['obtainedmarks']}
      Deleted: ${record['is_deleted'] == 1 ? 'YES' : 'NO'}
      Grade: ${record['grade']}
      --------------------------
      ''');
    }
  }

  Future close() async {
    if (_database != null) {
      print("Closing database connection...");
      await _database!.close();
      _database = null;
    }
  }
}