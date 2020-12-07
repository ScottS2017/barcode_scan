// MIT License
//
// Copyright (c) 2020 Simon Lightfoot, Scott Stoll, and Ikesh Pack
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
// KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

import 'package:barcode_scan/pages/home.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// This is a proof of concept for using a barcode reader
/// to read driver's license info in a Flutter app. This code is
/// somewhat over-commented due to the fact that it will be read
/// by many who are not yet experienced Flutter devs.
///
///  - Scott Stoll

/// Many devices have more than one camera
late final List<CameraDescription> cameras;

Future<void> main() async {
  /// Regarding ensureInitialized() :
  ///  1) We need to initialize Firebase and access the cameras
  ///     before calling runApp. However, runApp is what normally
  ///     handles creating the bindings that bind the framework to
  ///     the Flutter engine. These bindings include ServicesBinding,
  ///     which is needed in order to access platform channels
  ///  2) We solve this by calling ensureInitialized to tell the
  ///     app to create the bindings early, so ServicesBinding
  ///     is ready to use before we try to initialize Firebase
  ///     and access the camera
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
      home: Home(),
    );
  }
}