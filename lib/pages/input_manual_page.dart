import 'package:flutter/material.dart';
import '../helpers/produk_helper.dart';
import 'transaksi_page.dart';

class InputManualPage extends StatefulWidget {
  const InputManualPage({super.key});

  @override
  State<InputManualPage> createState() => _InputManualPageState();
}

class _InputManualPageState extends State<InputManualPage> {
  final skuController = TextEditingController();
  String pesanError = '';
  bool sedangCek = false;

  Future<void> lanjutkan() async {
    setState(() {
      sedangCek = true;
      pesanError = '';
    });

    final skuValid = await cariProdukValid(skuController.text);

    if (!mounted) return;

    if (skuValid == null) {
      setState(() {
        pesanError = 'SKU tidak ditemukan. Periksa kembali kode SKU-nya.';
        sedangCek = false;
      });
      return;
    }

    setState(() => sedangCek = false);

    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (context) => TransaksiPage(sku: skuValid)));

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input SKU Manual')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: skuController, decoration: const InputDecoration(labelText: 'Masukkan SKU')),
            const SizedBox(height: 16),
            if (pesanError.isNotEmpty) Text(pesanError, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: sedangCek ? null : lanjutkan,
              child: sedangCek
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Lanjut'),
            ),
          ],
        ),
      ),
    );
  }
}