import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class QRGeneratorPage extends StatefulWidget {
  const QRGeneratorPage({Key? key}) : super(key: key);

  @override
  State<QRGeneratorPage> createState() => _QRGeneratorPageState();
}

class _QRGeneratorPageState extends State<QRGeneratorPage> {
  final TextEditingController _dataController = TextEditingController();
  String _qrData = 'https://example.com';
  double _qrSize = 250.0;
  bool _isProcessing = false;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _dataController.text = _qrData;
  }

  // Simplified function to capture and share QR image
  Future<void> _captureAndShareQrImage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Capture the QR widget as an image
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert QR code to image');
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save the image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code_image.png');
      await file.writeAsBytes(pngBytes);

      // Share the file using Share.shareXFiles
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'QR Code for: $_qrData',
        subject: 'QR Code Image',
      );

      print("Share result: $result");

    } catch (e) {
      print("Error sharing QR code: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing QR image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Alternative method using just Share.share for text
  void _shareQrText() async {
    try {
      await Share.share(
        _qrData,
        subject: 'QR Code Data',
      );
    } catch (e) {
      print("Error sharing text: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing text: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Generator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _dataController,
              decoration: InputDecoration(
                labelText: 'Enter data for QR code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.text_fields),
              ),
              onChanged: (value) {
                setState(() {
                  _qrData = value.isEmpty ? 'https://example.com' : value;
                });
              },
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: RepaintBoundary(
                key: _qrKey,
                child: Container(
                  color: Colors.white,
                  child: QrImageView(
                    data: _qrData,
                    version: QrVersions.auto,
                    size: _qrSize,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('QR Size: '),
                Slider(
                  value: _qrSize,
                  min: 150,
                  max: 350,
                  divisions: 10,
                  label: _qrSize.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      _qrSize = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: _isProcessing
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.share),
              label: Text(_isProcessing ? 'Processing...' : 'Share QR Code Image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isProcessing ? null : _captureAndShareQrImage,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.text_fields),
              label: const Text('Share QR Code Data (Text)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.amber,
              ),
              onPressed: _isProcessing ? null : _shareQrText,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }
}