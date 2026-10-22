import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
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
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final skuTerbaca = barcode.rawValue;
    if (skuTerbaca == null || skuTerbaca.trim().isEmpty) return;

    setState(() {
      sedangProses = true;
      pesanError = '';
    });

    final skuValid = await ProductService.cariProdukValid(skuTerbaca);

    if (!mounted) return;

    if (skuValid == null) {
      setState(() {
        pesanError = 'SKU "$skuTerbaca" tidak ditemukan di sistem. Coba scan lagi.';
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
      appBar: AppBar(
        title: const Text('Scan Barcode Produk', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Column(
        children: [
          if (pesanError.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Text(pesanError, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
          Expanded(child: MobileScanner(onDetect: handleBarcode)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final nav = Navigator.of(context);
          await nav.push(MaterialPageRoute(builder: (context) => const InputManualPage()));
          if (!mounted) return;
          nav.pop();
        },
        label: const Text('Input Manual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.keyboard, color: Colors.white),
      ),
    );
  }
}
