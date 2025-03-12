import 'package:flutter/material.dart';

class ButtonPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Button Page"), // App bar title
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {}, // Empty function (button does nothing)
          child: Text("Press Me"), // Button text
        ),
      ),
    );
  }
}