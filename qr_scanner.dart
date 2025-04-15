import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool _permissionGranted = false;
  String _scanResult = 'Scan a QR code';

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _permissionGranted = status.isGranted;
    });

    if (status.isGranted) {
      // Ensure controller is started when permission is granted
      cameraController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: _permissionGranted
                ? MobileScanner(
              controller: cameraController,
              // Remove the formats parameter as it might be causing the error
              onDetect: (capture) {
                debugPrint('Detection occurred: ${capture.barcodes.length} barcodes found');
                final List<Barcode> barcodes = capture.barcodes;

                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  final barcode = barcodes.first;
                  debugPrint('Barcode detected: ${barcode.rawValue}');

                  // Stop scanning temporarily to avoid multiple detections
                  cameraController.stop();

                  setState(() {
                    _scanResult = barcode.rawValue!;
                  });

                  // Show result dialog
                  _showResultDialog(barcode.rawValue!);
                }
              },
            )
                : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Camera permission is required to scan QR codes',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _requestCameraPermission,
                    child: const Text('Request Permission'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Colors.blue.shade50,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Scan Result:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _scanResult,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(String result) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        title: const Text('QR Code Result'),
        content: SingleChildScrollView(
          child: Text(result),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Resume scanning after dialog is dismissed
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  cameraController.start();
                }
              });
            },
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              // You could add functionality to copy or share the result here
              // For example: Clipboard.setData(ClipboardData(text: result));
              Navigator.pop(context);
              // Resume scanning after dialog is dismissed
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  cameraController.start();
                }
              });
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}