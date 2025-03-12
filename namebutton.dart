import 'package:flutter/material.dart';

class CombinedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Combined Page"), // App bar title
      ),
      body: Center( // Wrap the Column in a Center widget
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center, // Center children horizontally
          children: [
            // Display the name
            Text(
              "M Ahtisham Ul Zama",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20), // Add some spacing
            // Display the button
            ElevatedButton(
              onPressed: () {}, // Button does nothing
              child: Text("Press Me"),
            ),
          ],
        ),
      ),
    );
  }
}