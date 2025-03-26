import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'loginsqlite.dart';

class ShowDataPage extends StatefulWidget {
  @override
  _ShowDataPageState createState() => _ShowDataPageState();
}

class _ShowDataPageState extends State<ShowDataPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
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

  // Logout method
  Future<void> _logout() async {
    // Clear logged-in state in database
    await DatabaseHelper().logoutUser();

    // Navigate back to login page and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPagesq()),
          (Route<dynamic> route) => false,
    );
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
            onPressed: _loadUsers,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
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
                ? Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? Center(child: Text('No data found'))
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Password')),
                ],
                rows: filteredUsers.map((user) {
                  return DataRow(
                    cells: [
                      DataCell(Text(user['id'].toString())),
                      DataCell(Text(user['email'])),
                      DataCell(Text(user['password'])),
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