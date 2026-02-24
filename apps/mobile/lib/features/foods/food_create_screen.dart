import 'package:flutter/material.dart';

class FoodCreateScreen extends StatelessWidget {
  const FoodCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Create Food')), body: const Center(child: Text('Food Create Screen')));
  }
}
