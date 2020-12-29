import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

import 'home.dart';

void main() {
  runApp(SiNote());
}

class SiNote extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: MaterialApp(
        title: 'Sinote',
        theme: ThemeData.dark(),
        home: Home(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
