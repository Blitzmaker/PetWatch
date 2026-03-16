import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/app_shell.dart';
import '../../core/providers.dart';

class BarcodeScanScreen extends ConsumerStatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  final _barcode = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();

  String? _message;
  Map<String, dynamic>? _food;
  bool _isProcessingScan = false;

  String _normalizeBarcodeValue(String raw) {
    return raw.trim();
  }

  Future<void> _lookup() async {
    final barcode = _normalizeBarcodeValue(_barcode.text);
    if (barcode.isEmpty) {
      setState(() {
        _food = null;
        _message = 'Bitte einen Barcode scannen oder eingeben.';
      });
      return;
    }

    _barcode.text = barcode;

    try {
      final response = await ref.read(apiClientProvider).dio.get('/foods/by-barcode/$barcode');
      setState(() {
        _food = response.data as Map<String, dynamic>;
        _message = 'Gefunden: ${response.data['name']} (Barcode: $barcode)';
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        setState(() {
          _food = null;
          _message = 'Kein Treffer für Barcode $barcode. Du kannst ein neues Futter anlegen.';
        });
        return;
      }
      setState(() {
        _food = null;
        _message = 'Fehler: ${e.message}';
      });
    }
  }

  Future<void> _handleDetectedBarcode(BarcodeCapture capture) async {
    if (_isProcessingScan) return;
    final rawValue = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    final barcode = _normalizeBarcodeValue(rawValue);
    if (barcode.isEmpty) return;

    _isProcessingScan = true;
    _scannerController.stop();

    setState(() {
      _barcode.text = barcode;
      _message = 'Barcode erkannt: $barcode';
    });

    await _lookup();
    _isProcessingScan = false;
  }

  Future<void> _createFood() async {
    await Navigator.pushNamed(context, '/foods/create', arguments: _barcode.text.trim());
  }

  @override
  void dispose() {
    _barcode.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 1,
      title: 'Barcode scannen',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleDetectedBarcode,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _barcode, decoration: const InputDecoration(labelText: 'Barcode')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: _lookup, child: const Text('Suchen'))),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _scannerController.start();
                      setState(() => _message = 'Scanner gestartet.');
                    },
                    child: const Text('Scanner neu starten'),
                  ),
                ),
              ],
            ),
            if (_message != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_message!)),
            if (_food != null)
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _food),
                child: const Text('Für Mahlzeit übernehmen'),
              ),
            if (_food == null)
              OutlinedButton(
                onPressed: _createFood,
                child: const Text('Neues Futter anlegen'),
              ),
          ],
        ),
      ),
    );
  }
}
