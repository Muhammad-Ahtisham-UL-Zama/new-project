import 'package:flutter/material.dart';
import 'dart:convert';
import 'login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Check if this is the initial route
  bool isInitialRoute = false;

  @override
  void initState() {
    super.initState();
    // Check if there's a previous route in the stack
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isInitialRoute = Navigator.of(context).canPop() == false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent default back button behavior if this is the initial route
      onWillPop: () async {
        if (isInitialRoute) {
          // If this is the initial route, don't allow regular back navigation
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple.shade700,
          elevation: 4,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Check if we can pop (there's a screen to go back to)
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                // If we can't pop (this is the first screen), show logout dialog
                _showLogoutConfirmation(context);
              }
            },
          ),
          title: Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          // Add a drawer menu icon if this is the initial route
          actions: isInitialRoute ? [
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ] : null,
        ),
        // Add drawer if this is the initial route
        drawer: isInitialRoute ? _buildDrawer(context) : null,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purpleAccent.shade100,
                Colors.purple.shade200,
                Colors.deepPurple.shade300,
                Colors.indigo.shade400,
              ],
              stops: const [0.1, 0.4, 0.7, 0.9],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          spreadRadius: 5,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: 32,
                              color: Colors.purple.shade700,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'User Profile',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Profile Picture
                        Center(
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: widget.userData['profileImage'] != null
                                ? MemoryImage(base64Decode(widget.userData['profileImage']))
                                : null,
                            backgroundColor: Colors.purple.shade300,
                            child: widget.userData['profileImage'] == null
                                ? Icon(Icons.person, size: 60, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // User Details
                        _buildProfileDetail('Name', widget.userData['name']),
                        const SizedBox(height: 10),
                        _buildProfileDetail('Email', widget.userData['email']),
                        const SizedBox(height: 10),
                        _buildProfileDetail('City', widget.userData['city']),
                        const SizedBox(height: 10),
                        _buildProfileDetail('Gender', widget.userData['gender']),
                        const SizedBox(height: 10),
                        _buildProfileDetail('Address', widget.userData['address']),
                        const SizedBox(height: 20),

                        // Log Out Button
                        ElevatedButton(
                          onPressed: () => _logout(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.shade700,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Log Out',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build profile details
  Widget _buildProfileDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? 'Not provided', // Add a fallback in case value is null
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.purple.shade700,
          ),
        ),
      ],
    );
  }

  // Logout function
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    // Remove this line: await prefs.remove('userData');

    // Navigate to LoginPage and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
    );
  }

  // Show logout confirmation dialog
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Navigation'),
          content: Text('Do you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _logout(context); // Logout user
              },
            ),
          ],
        );
      },
    );
  }

  // Build drawer for navigation
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade700,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: widget.userData['profileImage'] != null
                      ? MemoryImage(base64Decode(widget.userData['profileImage']))
                      : null,
                  backgroundColor: Colors.purple.shade300,
                  child: widget.userData['profileImage'] == null
                      ? Icon(Icons.person, size: 30, color: Colors.white)
                      : null,
                ),
                SizedBox(height: 10),
                Text(
                  widget.userData['name'] ?? 'User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                Text(
                  widget.userData['email'] ?? '',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.calculate),
            title: Text('Calculator'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Navigate to calculator page
              // You'll need to adjust this based on your navigation structure
            },
          ),
          ListTile(
            leading: Icon(Icons.table_chart),
            title: Text('Data Table'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Navigate to table page
            },
          ),
          // Add more menu items as needed
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _logout(context);
            },
          ),
        ],
      ),
    );
  }
}