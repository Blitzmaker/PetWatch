import 'package:flutter/material.dart';
import '../../core/app_shell.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _duration = TextEditingController();
  String _intensity = 'MEDIUM';

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 2,
      title: 'Aktivität erfassen',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _intensity,
              decoration: const InputDecoration(labelText: 'Intensität'),
              items: const [
                DropdownMenuItem(value: 'LOW', child: Text('Niedrig')),
                DropdownMenuItem(value: 'MEDIUM', child: Text('Mittel')),
                DropdownMenuItem(value: 'HIGH', child: Text('Hoch')),
              ],
              onChanged: (value) => setState(() => _intensity = value ?? 'MEDIUM'),
            ),
            TextField(
              controller: _duration,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Dauer in Minuten'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aktivitäts-Tracking folgt als nächster Schritt.')));
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
