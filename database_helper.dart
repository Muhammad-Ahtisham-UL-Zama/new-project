import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  // Factory constructor to return the singleton instance
  factory DatabaseHelper() {
    return _instance;
  }

  // Private internal constructor
  DatabaseHelper._internal();

  // Database object
  static Database? _database;

  // Getter for the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'user_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create the table
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        password TEXT
      )
    ''');
  }

  // Insert a new user
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert('users', user);
  }

  // Fetch all users
  Future<List<Map<String, dynamic>>> getUsers() async {
    Database db = await database;
    return await db.query('users');
  }

  // Fetch a user by email
  // Future<Map<String, dynamic>?> getUserByEmail(String email) async {
  //   Database db = await database;
  //   List<Map<String, dynamic>> result = await db.query(
  //     'users',
  //     where: 'email = ?',
  //     whereArgs: [email],
  //   );
  //   return result.isNotEmpty ? result.first : null;
  // }
}