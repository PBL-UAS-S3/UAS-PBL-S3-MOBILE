import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const MyApp());
}

// ========================================================================
// MY APP
// ========================================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthCheckPage(),
    );
  }
}

// ========================================================================
// AUTH CHECK PAGE (cek token tersimpan sebelum tentukan halaman awal)
// ========================================================================

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProductListPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// ========================================================================
// LOGIN PAGE
// ========================================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String pesanError = '';

  Future<void> login() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['role']);
        await prefs.setString('nama', data['nama']);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProductListPage()),
        );
      } else {
        setState(() {
          pesanError = 'Email atau password salah';
        });
      }
    } catch (e) {
      setState(() {
        pesanError = 'Gagal konek ke server: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            if (pesanError.isNotEmpty)
              Text(pesanError, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: login, child: const Text('Masuk')),
          ],
        ),
      ),
    );
  }
}

// ========================================================================
// PRODUCT LIST PAGE
// ========================================================================

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List products = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final response = await http.get(Uri.parse('http://localhost:3000/products'));
    setState(() {
      products = jsonDecode(response.body);
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScannerPage()),
              );
              fetchProducts(); // refresh otomatis setelah balik dari scan/transaksi
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchProducts,
        child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final item = products[index];
            return ListTile(
              title: Text(item['nama']),
              subtitle: Text('SKU: ${item['sku']}'),
              trailing: Text('Stok: ${item['stok_saat_ini']}'),
            );
          },
        ),
      ),
    );
  }
}

// ========================================================================
// HELPER: cek SKU valid ke server, dipakai Scanner & Input Manual
// ========================================================================

Future<String?> cariProdukValid(String skuInput) async {
  final response = await http.get(Uri.parse('http://localhost:3000/products'));
  final List produk = jsonDecode(response.body);

  final skuDicari = skuInput.trim().toUpperCase();

  for (final p in produk) {
    if (p['sku'].toString().toUpperCase() == skuDicari) {
      return p['sku']; // balikin SKU asli (sesuai casing di database)
    }
  }
  return null; // tidak ditemukan
}

// ========================================================================
// SCANNER PAGE (Kamera + fallback Input Manual)
// ========================================================================

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

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TransaksiPage(sku: skuValid)),
    );

    setState(() => sedangProses = false);
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InputManualPage()),
          );
        },
        label: const Text('Input Manual'),
        icon: const Icon(Icons.keyboard),
      ),
    );
  }
}

// ========================================================================
// INPUT MANUAL PAGE (fallback tanpa kamera, dengan validasi SKU)
// ========================================================================

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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TransaksiPage(sku: skuValid)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input SKU Manual')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: skuController,
              decoration: const InputDecoration(labelText: 'Masukkan SKU'),
            ),
            const SizedBox(height: 16),
            if (pesanError.isNotEmpty)
              Text(pesanError, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: sedangCek ? null : lanjutkan,
              child: sedangCek
                  ? const SizedBox(
                      height: 16, width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lanjut'),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================================================
// TRANSAKSI PAGE (form catat transaksi masuk/keluar)
// ========================================================================

class TransaksiPage extends StatefulWidget {
  final String sku;
  const TransaksiPage({super.key, required this.sku});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  String tipe = 'in';
  final jumlahController = TextEditingController();
  String pesan = '';

  Future<void> kirimTransaksi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('http://localhost:3000/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sku': widget.sku,
          'tipe': tipe,
          'jumlah': int.tryParse(jumlahController.text) ?? 0,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil! Stok baru: ${data['stok_baru']}')),
        );
        // Langsung lompat ke halaman paling awal (Daftar Produk),
        // bukan cuma mundur satu langkah ke Input SKU/Scanner
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() {
          pesan = data['error'] ?? 'Gagal menyimpan transaksi';
        });
      }
    } catch (e) {
      setState(() {
        pesan = 'Tidak dapat terhubung ke server: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SKU: ${widget.sku}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jenis Transaksi'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: const Text('Masuk'),
                    value: 'in',
                    groupValue: tipe,
                    onChanged: (v) => setState(() => tipe = v.toString()),
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: const Text('Keluar'),
                    value: 'out',
                    groupValue: tipe,
                    onChanged: (v) => setState(() => tipe = v.toString()),
                  ),
                ),
              ],
            ),
            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah'),
            ),
            const SizedBox(height: 16),
            if (pesan.isNotEmpty)
              Text(pesan, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: kirimTransaksi,
              child: const Text('Simpan Transaksi'),
            ),
          ],
        ),
      ),
    );
  }
}