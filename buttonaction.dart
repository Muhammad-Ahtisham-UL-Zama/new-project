import 'package:flutter/material.dart';

class DynamicNamePage extends StatefulWidget {
  @override
  _DynamicNamePageState createState() => _DynamicNamePageState();
}

class _DynamicNamePageState extends State<DynamicNamePage> {
  // List of names to display
  final List<String> names = [
    "Azeem",
    "Ali Hamza",
    "Azeem Shakir",
    "Umer",
    "Asad",
    "Awais",
  ];

  // Variable to store the current name
  String currentName = " "; // Initialize with a space to avoid layout shift

  // Function to update the name when the button is pressed
  void _updateName() {
    setState(() {
      // Select the next name from the list
      currentName = names[(names.indexOf(currentName) + 1) % names.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dynamic Name Page"), // App bar title
      ),
      body: Center( // Wrap the Column in a Center widget
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
            children: [
              // Button at the top
              ElevatedButton(
                onPressed: _updateName, // Call _updateName when pressed
                child: Text("Show Name"),
              ),
              SizedBox(height: 20), // Add some spacing
              // Display the current name
              Text(
                currentName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}