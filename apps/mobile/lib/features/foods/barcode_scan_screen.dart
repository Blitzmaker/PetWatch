import 'package:flutter/material.dart';

class BarcodeScanScreen extends StatelessWidget {
  const BarcodeScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Barcode Scan')), body: const Center(child: Text('Barcode Scan Screen')));
  }
}
