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
      version: 2, // Increased version to handle migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create the table
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        password TEXT,
        is_logged_in INTEGER DEFAULT 0
      )
    ''');
  }

  // Handle database upgrade
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE users ADD COLUMN is_logged_in INTEGER DEFAULT 0
      ''');
    }
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

  // Login method to validate user credentials
  Future<bool> loginUser(String email, String password) async {
    Database db = await database;

    // First, reset all logged-in states
    await db.update('users', {'is_logged_in': 0});

    // Then, validate and set current user as logged in
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      // Set this user as logged in
      await db.update(
          'users',
          {'is_logged_in': 1},
          where: 'email = ?',
          whereArgs: [email]
      );
      return true;
    }
    return false;
  }

  // Check if a user is currently logged in
  Future<bool> isUserLoggedIn() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'is_logged_in = ?',
      whereArgs: [1],
    );
    return result.isNotEmpty;
  }

  // Logout method
  Future<void> logoutUser() async {
    Database db = await database;
    await db.update('users', {'is_logged_in': 0});
  }

  // Get currently logged-in user
  Future<Map<String, dynamic>?> getCurrentUser() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'is_logged_in = ?',
      whereArgs: [1],
    );
    return result.isNotEmpty ? result.first : null;
  }
}