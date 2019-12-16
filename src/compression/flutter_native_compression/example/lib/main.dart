import 'package:flutter/material.dart';

import 'package:flutter_native_compression/flutter_native_compression.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _lz4Version;

  @override
  void initState() {
    super.initState();
    setState(() {
      try {
        _lz4Version = FlutterNativeCompression.lz4.getVersionString();
      } catch (error) {
        _lz4Version = error.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Container(
            padding: EdgeInsets.only(left: 10, right: 10, top: 20, bottom: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('lz4 version: $_lz4Version'),
              ],
            )),
      ),
    );
  }
}
