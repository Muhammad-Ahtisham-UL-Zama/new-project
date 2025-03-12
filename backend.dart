import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileDataService {
  // Singleton pattern to ensure only one instance
  static final ProfileDataService _instance = ProfileDataService._internal();

  factory ProfileDataService() {
    return _instance;
  }

  ProfileDataService._internal();

  // Load profile data from SharedPreferences
  Future<List<Map<String, dynamic>>> loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? entryStrings = prefs.getStringList('entries');

    // Debug: Print the retrieved entries
    print('Retrieved Entries: $entryStrings');

    if (entryStrings != null) {
      return entryStrings.map((entry) => jsonDecode(entry) as Map<String, dynamic>).toList();
    } else {
      return [];
    }
  }

  // Delete an entry
  Future<bool> deleteEntry(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? entryStrings = prefs.getStringList('entries') ?? [];

    if (index >= 0 && index < entryStrings.length) {
      entryStrings.removeAt(index);
      await prefs.setStringList('entries', entryStrings);
      return true;
    }
    return false;
  }

  // Add a new entry
  Future<bool> addEntry(Map<String, dynamic> entry) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> entryStrings = prefs.getStringList('entries') ?? [];

    entryStrings.add(jsonEncode(entry));
    return await prefs.setStringList('entries', entryStrings);
  }

  // Update an entry
  Future<bool> updateEntry(int index, Map<String, dynamic> updatedEntry) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? entryStrings = prefs.getStringList('entries') ?? [];

    if (index >= 0 && index < entryStrings.length) {
      entryStrings[index] = jsonEncode(updatedEntry);
      return await prefs.setStringList('entries', entryStrings);
    }
    return false;
  }
}