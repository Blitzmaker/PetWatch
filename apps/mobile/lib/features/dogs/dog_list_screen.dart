import 'package:flutter/material.dart';

class DogListScreen extends StatelessWidget {
  const DogListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dogs')),
      body: ListView(children: const [ListTile(title: Text('Dog List Screen'))]),
      floatingActionButton: FloatingActionButton(onPressed: () => Navigator.pushNamed(context, '/dogs/create'), child: const Icon(Icons.add)),
    );
  }
}
