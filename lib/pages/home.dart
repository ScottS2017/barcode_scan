import 'dart:typed_data';

/// Don't import main like this in a production app.
/// This app is just a quick and dirty proof of concept
import 'package:barcode_scan/main.dart';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';


@immutable
class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final BarcodeDetector barcodeDetector = FirebaseVision.instance.barcodeDetector(

    /// Barcode format can be anything including UPC, ean, code, qr,
    /// and here pdf417 is for driver's licenses
    BarcodeDetectorOptions(barcodeFormats: BarcodeFormat.pdf417),
  );

  late final CameraController _controller;

  Future? _processing;
  bool _activelyScanning = true;

  @override
  void initState() {
    super.initState();
    /// We only care about camera[0], this should be the back camera.
    /// For pdf417 the resolution has to be ultraHigh because the barcode is huge
    _controller = CameraController(cameras[0], ResolutionPreset.ultraHigh);
    _controller.initialize().then((_) {
      /// Proceed only if this state object is mounted in the widget tree
      if (!mounted) {
        return;
      }
      setState(() {});
      _controller.startImageStream(_onLatestImageAvailable);
    });
  }

  void _onLatestImageAvailable(CameraImage image) {
    if (!_activelyScanning || _processing != null) {
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
            int i = 1;
            final items = barcodes.map((b) => '${i++}. ${b.displayValue}\n${b.rawValue}').join('\n\n');
            return AlertDialog(
              content: Text(items),
              actions: [
                FlatButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
        if(mounted){
          setState(() {
            _activelyScanning = false;
          });
        }
      }
    }).whenComplete(() => _processing = null);
  }

  @override
  void dispose() {
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
                  if (_activelyScanning)
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

      floatingActionButton: _activelyScanning
        ?

      /// Cancel FAB
      FloatingActionButton(
        onPressed: () {
          setState(() {
            _activelyScanning = false;
          });
        },
        backgroundColor: Colors.white,
        child: Icon(
          Icons.cancel,
          color: Colors.red,
          size: 52,
        ), //Change Icon

        /// Refresh FAB
      )
        : FloatingActionButton(
        onPressed: () {
          setState(() {
            _activelyScanning = true;
          });
        },
        child: Icon(Icons.refresh), //Change Icon
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, //Change for different locations
    );
  }
}
