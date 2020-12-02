import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';

late final List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  cameras = await availableCameras();
  runApp(ScannerApp());
}

class ScannerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customizable Barcode Scanner',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: Scanner(),
    );
  }
}

@immutable
class Scanner extends StatefulWidget {
  const Scanner({Key? key}) : super(key: key);

  @override
  _ScannerState createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> with SingleTickerProviderStateMixin {
  final BarcodeDetector barcodeDetector = FirebaseVision.instance.barcodeDetector(
    BarcodeDetectorOptions(barcodeFormats: BarcodeFormat.pdf417),
  );

  late final CameraController _controller;
  late final AnimationController _animationController;

  Future? _processing;
  List<Barcode> _barcodes = [];

  bool get hasBarcodes => (_barcodes.length != 0);
  bool _showGreenBoxAndRedFAB = true;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(cameras[0], ResolutionPreset.ultraHigh);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      _controller.startImageStream(_onLatestImageAvailable);
    });
  }

  void _onLatestImageAvailable(CameraImage image) {
    if (_processing != null) {
      return;
    }

    final metadata = FirebaseVisionImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rawFormat: image.format.raw,
      planeData: image.planes.map((plane) {
        return FirebaseVisionImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      }).toList(),
    );

    final total = image.planes.fold<int>(0, (prev, el) => prev + el.bytes.length);
    final bytes = Uint8List(total);
    for (int offset = 0, i = 0; offset < total;) {
      final plane = image.planes[i++];
      bytes.setAll(offset, plane.bytes);
      offset += plane.bytes.length;
    }

    final visionImage = FirebaseVisionImage.fromBytes(bytes, metadata);
    _processing = barcodeDetector.detectInImage(visionImage).then((List<Barcode> barcodes) async {
      if (barcodes.isNotEmpty) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            _controller.stopImageStream();
            int i = 1;
            final items = barcodes.map((b) => '${i++}. ${b.displayValue}').join('\n');
            return AlertDialog(
             content: Text(items),
              actions: [
                FlatButton(
                  onPressed: () {
                    _showGreenBoxAndRedFAB = false;
                    _showGreenFAB = true;
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      }
      if (mounted) {
        setState(() {
          _barcodes = barcodes;
          _processing = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.stopImageStream();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(child: Text('Customizable Barcode Scanner')),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: _controller.value.previewSize.height,
                    height: _controller.value.previewSize.width,
                    child: Stack(
                      children: [
                        CameraPreview(_controller),
                      ],
                    ),
                  ),
                  if (_showGreenBoxAndRedFAB)
                    Center(
                      child: Container(
                        /// Change sizes to conform with responsive design!
                        height: 800,
                        width: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 6,
                            color: (Colors.green[300])!,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: _showGreenBoxAndRedFAB ? FloatingActionButton(
        onPressed:  () {
          _showGreenBoxAndRedFAB = false;
          setState(() {});
          _controller.stopImageStream();
        },
        backgroundColor: Colors.white,
        child: Icon(Icons.cancel,
        color: Colors.red,
        size: 52,), //Change Icon
      ) : FloatingActionButton(
        onPressed:  () {
          _barcodes.clear();
          _showGreenBoxAndRedFAB = true;
          setState(() {});
          _controller.startImageStream(_onLatestImageAvailable);
        },
        child: Icon(Icons.refresh), //Change Icon
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, //Change for different locations
    );
  }
}

