import 'package:flutter/material.dart';
import 'database_helper.dart'; // Import your DatabaseHelper class

class ShowDataPage extends StatefulWidget {
  @override
  _ShowDataPageState createState() => _ShowDataPageState();
}

class _ShowDataPageState extends State<ShowDataPage> {
  List<Map<String, dynamic>> _users = []; // List to store user data
  bool _isLoading = false; // To show a loading indicator
  TextEditingController _searchController = TextEditingController(); // For search functionality

  @override
  void initState() {
    super.initState();
    _loadUsers(); // Load users when the page is initialized
  }

  // Fetch users from the database
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      List<Map<String, dynamic>> users = await DatabaseHelper().getUsers();
      setState(() {
        _users = users;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  // Filter users by email
  List<Map<String, dynamic>> _filterUsers(String query) {
    return _users.where((user) {
      final email = user['email'].toString().toLowerCase();
      return email.contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filterUsers(_searchController.text);

    return Scaffold(
      appBar: AppBar(
        title: Text('User Data'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUsers, // Refresh the data
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Refresh the UI when the search query changes
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator()) // Show loading indicator
                : filteredUsers.isEmpty
                ? Center(child: Text('No data found')) // Show message if no data
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Allow horizontal scrolling
              child: DataTable(
                columns: [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Password')),
                ],
                rows: filteredUsers.map((user) {
                  return DataRow(
                    cells: [
                      DataCell(Text(user['id'].toString())), // ID
                      DataCell(Text(user['email'])), // Email
                      DataCell(Text(user['password'])), // Password
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}