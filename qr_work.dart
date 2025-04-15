import 'package:flutter/material.dart';
import 'qr_generator.dart';
import 'qr_scanner.dart';

class QRWorkPage extends StatelessWidget {
  const QRWorkPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Tools'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Code Scanner Button
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text(
                'Scan QR Code',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRScannerPage()),
                );
              },
            ),
            const SizedBox(height: 30),
            // QR Code Generator Button
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code),
              label: const Text(
                'Generate QR Code',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRGeneratorPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}