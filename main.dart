import 'package:flutter/material.dart';
import 'name.dart'; // Import the name.dart file
import 'button.dart'; //Import the button.dart file
import 'namebutton.dart'; //Import the namebutton.dart file
import 'buttonaction.dart'; //Import the buttonaction.dart file
import 'register.dart'; // Import the register.dart file
import 'profile.dart'; //Import the profile.dart file
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
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
              title: const Text('Register Data'), // New menu item
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyProfile()), // Navigate to MyProfilePage
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