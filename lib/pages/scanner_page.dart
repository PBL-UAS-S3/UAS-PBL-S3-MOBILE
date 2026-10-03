import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../helpers/produk_helper.dart';
import 'input_manual_page.dart';
import 'transaksi_page.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool sedangProses = false;
  String pesanError = '';

  Future<void> handleBarcode(BarcodeCapture capture) async {
    if (sedangProses) return;
    final barcode = capture.barcodes.first;
    final skuTerbaca = barcode.rawValue;
    if (skuTerbaca == null) return;

    setState(() {
      sedangProses = true;
      pesanError = '';
    });

    final skuValid = await cariProdukValid(skuTerbaca);

    if (!mounted) return;

    if (skuValid == null) {
      setState(() {
        pesanError = 'SKU "$skuTerbaca" tidak ditemukan. Coba scan lagi.';
        sedangProses = false;
      });
      return;
    }

    await Navigator.push(context, MaterialPageRoute(builder: (context) => TransaksiPage(sku: skuValid)));

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode Produk')),
      body: Column(
        children: [
          if (pesanError.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Text(pesanError, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(child: MobileScanner(onDetect: handleBarcode)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const InputManualPage()));
          if (!mounted) return;
          Navigator.pop(context);
        },
        label: const Text('Input Manual'),
        icon: const Icon(Icons.keyboard),
      ),
    );
  }
}