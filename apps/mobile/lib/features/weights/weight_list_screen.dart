import 'package:flutter/material.dart';

class WeightListScreen extends StatelessWidget {
  const WeightListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weights')),
      body: const Center(child: Text('Weight List Screen')),
      floatingActionButton: FloatingActionButton(onPressed: () => Navigator.pushNamed(context, '/weights/create'), child: const Icon(Icons.add)),
    );
  }
}
