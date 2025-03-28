import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Add this import for jsonDecode
import 'name.dart'; // Import the name.dart file
import 'button.dart'; // Import the button.dart file
import 'namebutton.dart'; // Import the namebutton.dart file
import 'buttonaction.dart'; // Import the buttonaction.dart file
import 'register.dart'; // Import the register.dart file
import 'profile.dart'; // Import the profile.dart file
import 'signup.dart'; // Import the signup.dart file
import 'login.dart'; // Import the login.dart file
import 'profilepage.dart'; // Import the profilepage.dart file
import 'vertical_scroll.dart'; // Import the vertical_scroll.dart file
import 'horizontal_scroll.dart'; // Import the horizontal_scroll.dart file
import 'nolistview.dart'; // Import the nolistview.dart file
import 'signupsqlite.dart'; // Import the signupsqlite.dart file
import 'loginsqlite.dart'; // Import the loginsqlite.dart file
import 'student_page.dart'; // Import the student_page.dart file

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Wrapper(), // Use the Wrapper widget as the home
    );
  }
}

// Wrapper widget to check login status and retrieve user data
class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          if (snapshot.data?['isLoggedIn'] == true) {
            // User is logged in, navigate to ProfilePage with userData
            return ProfilePage(userData: snapshot.data?['userData'] ?? {});
          } else {
            // User is not logged in, show HomeScreen
            return HomeScreen();
          }
        }
      },
    );
  }

  // Method to check login status and retrieve userData
  Future<Map<String, dynamic>> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userDataString = prefs.getString('userData');
    final userData = userDataString != null ? jsonDecode(userDataString) : {};

    return {
      'isLoggedIn': isLoggedIn,
      'userData': userData,
    };
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BGNU"), // Header with "BGNU"
      ),
      // Hamburger menu (Drawer)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              title: const Text('SQlite'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignupPagesq()),
                );
              },
            ),
            ListTile(
              title: const Text('LoginSQ'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPagesq()),
                );
              },
            ),
            ListTile(
              title: const Text('Marks Cal'), // New menu item
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentsPage()), // Navigate to NamePage
                );
              },
            ),
            ListTile(
              title: const Text('Calculator'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CalculatorPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Data Table'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TablePage()),
                );
              },
            ),
            ListTile(
              title: const Text('Name'), // New menu item
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NamePage()), // Navigate to NamePage
                );
              },
            ),
            ListTile(
              title: const Text('Button'), // New menu item
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ButtonPage()), // Navigate to NamePage
                );
              },
            ),
            ListTile(
              title: const Text('Combine'), // New menu item
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CombinedPage()), // Navigate to NameButtonPage
                );
              },
            ),
            ListTile(
              title: const Text('Button Action'), // New menu item
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DynamicNamePage()), // Navigate to RegisterPage
                );
              },
            ),
            ListTile(
              title: const Text('Register'), // New menu item
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()), // Navigate to RegisterPage
                );
              },
            ),
            ListTile(
              title: const Text('Vertical'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ImageListScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Horizontal'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HorizontalImageGallery()),
                );
              },
            ),
            ListTile(
              title: const Text('No List'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ImageGridGallery()),
                );
              },
            ),
            ListTile(
              title: const Text('Register Data'), // New menu item
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyProfile()), // Navigate to MyProfilePage
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Sign Up'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      // Body of the main page
      body: Center(
        child: Text(
          'HOME PAGE', // Body with "HOME PAGE"
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// Rest of your code (CalculatorPage, TablePage, etc.)

class CalculatorPage extends StatefulWidget {
  @override
  _CalculatorPageState createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  TextEditingController num1Controller = TextEditingController();
  TextEditingController num2Controller = TextEditingController();
  String selectedOperation = '+';
  double result = 0;
  Color resultColor = Colors.blue; // Match calculate button color

  void calculate() {
    double num1 = double.tryParse(num1Controller.text) ?? 0;
    double num2 = double.tryParse(num2Controller.text) ?? 0;

    setState(() {
      switch (selectedOperation) {
        case '+':
          result = num1 + num2;
          break;
        case '-':
          result = num1 - num2;
          break;
        case '*':
          result = num1 * num2;
          break;
        case '/':
          result = num2 != 0 ? num1 / num2 : 0;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Calculator")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: num1Controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Enter first number", border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedOperation,
              decoration: InputDecoration(border: OutlineInputBorder()),
              items: ['+', '-', '*', '/'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(fontSize: 18)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedOperation = newValue!;
                });
              },
            ),
            SizedBox(height: 10),
            TextField(
              controller: num2Controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Enter second number", border: OutlineInputBorder()),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: calculate,
              child: Text("Calculate", style: TextStyle(fontSize: 18)),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Result: $result",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TablePage extends StatelessWidget {
  final List<Map<String, String>> students = [
    {"Name": "Ali Khan", "Father": "Mr. Khan", "Phone": "1234567890", "CGPA": "3.8"},
    {"Name": "Sara Ahmed", "Father": "Mr. Ahmed", "Phone": "9876543210", "CGPA": "3.5"},
    {"Name": "Usman Tariq", "Father": "Mr. Tariq", "Phone": "5556667778", "CGPA": "3.9"},
    {"Name": "Fatima Noor", "Father": "Mr. Noor", "Phone": "1122334455", "CGPA": "3.6"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Student Data")),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          border: TableBorder.all(color: Colors.black, width: 1),
          columns: [
            DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Father Name", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Phone Number", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("CGPA", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: List.generate(students.length, (index) {
            final student = students[index];
            final Color rowColor = index % 2 == 0 ? Colors.grey[200]! : Colors.white;
            return DataRow(
              color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                return rowColor;
              }),
              cells: [
                DataCell(Text(student["Name"]!)),
                DataCell(Text(student["Father"]!)),
                DataCell(Text(student["Phone"]!)),
                DataCell(Text(student["CGPA"]!)),
              ],
            );
          }),
        ),
      ),
    );
  }
}