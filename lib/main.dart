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
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthCheckPage(),
    );
  }
}

// ========================================================================
// AUTH CHECK PAGE
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
        MaterialPageRoute(builder: (context) => const MainShell()),
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
  bool loading = false;

  Future<void> login() async {
    setState(() {
      loading = true;
      pesanError = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['role'] != 'staff') {
          setState(() {
            pesanError = 'Aplikasi mobile ini khusus untuk akun Staf. Gunakan web dashboard untuk akun Manager.';
            loading = false;
          });
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['role']);
        await prefs.setString('nama', data['nama']);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainShell()),
        );
      } else {
        setState(() {
          pesanError = data['error'] ?? 'Email atau password salah';
        });
      }
    } catch (e) {
      setState(() {
        pesanError = 'Gagal konek ke server: $e';
      });
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('📦', style: TextStyle(fontSize: 40))),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Welcome Back!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Sign in to Your account.', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 32),

              const Text('Email', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(hintText: 'Enter your email', border: UnderlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Password', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Enter your password', border: UnderlineInputBorder()),
              ),

              if (pesanError.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(pesanError, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.grey.shade600),
                    children: [
                      const TextSpan(text: 'New here? '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterPage()),
                            );
                          },
                          child: Text(
                            'Create an account',
                            style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================================================
// REGISTER PAGE (khusus staf)
// ========================================================================

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final teleponController = TextEditingController();
  String pesan = '';
  bool sukses = false;
  bool loading = false;

  Future<void> register() async {
    setState(() {
      loading = true;
      pesan = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/auth/register-staff'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': namaController.text,
          'email': emailController.text,
          'password': passwordController.text,
          'telepon': teleponController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        setState(() {
          sukses = true;
          pesan = 'Akun berhasil dibuat! Silakan login.';
        });
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        setState(() {
          pesan = data['error'] ?? 'Registrasi gagal';
        });
      }
    } catch (e) {
      setState(() {
        pesan = 'Gagal konek ke server: $e';
      });
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('📦', style: TextStyle(fontSize: 40))),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Create an account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Daftar sebagai Staf Gudang.', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 28),

              const Text('Full Name', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              TextField(
                controller: namaController,
                decoration: const InputDecoration(hintText: 'Enter your full name', border: UnderlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Email', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(hintText: 'Enter your email', border: UnderlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Password', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Enter your password', border: UnderlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Nomor Telepon (Opsional)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              TextField(
                controller: teleponController,
                decoration: const InputDecoration(hintText: '08xx-xxxx-xxxx', border: UnderlineInputBorder()),
              ),

              const SizedBox(height: 16),
              Text(
                'Dengan membuat akun, kamu setuju akun ini terdaftar sebagai Staf Gudang.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),

              if (pesan.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sukses ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pesan,
                    style: TextStyle(color: sukses ? Colors.green.shade700 : Colors.red.shade700, fontSize: 13),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.grey.shade600),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Sign in',
                            style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================================================
// MAIN SHELL — bottom nav 5 tab
// ========================================================================

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 1; // default buka tab "Items"
  List products = [];
  bool loadingProduk = true;

  final titles = ['Workflows', 'Items', 'Search', 'Notifications', 'Menu'];
  final subtitles = [
    'Streamline warehouse operations',
    'Daftar produk gudang',
    'Cari produk atau scan',
    'Pemberitahuan terbaru',
    'Profil & pengaturan akun',
  ];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() => loadingProduk = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/products'));
      setState(() {
        products = jsonDecode(response.body);
      });
    } catch (e) {
      // biarkan tetap list kosong, tampilan tab akan tunjukkin state kosong
    }
    setState(() => loadingProduk = false);
  }

  Future<void> bukaScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerPage()),
    );
    fetchProducts();
  }

  Future<void> bukaInputManual() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InputManualPage()),
    );
    fetchProducts();
  }

  void tampilkanPilihanTambah() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CATAT TRANSAKSI', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.keyboard, color: Colors.blue)),
                  title: const Text('Input Manual'),
                  subtitle: const Text('Ketik SKU produk sendiri'),
                  onTap: () {
                    Navigator.pop(context);
                    bukaInputManual();
                  },
                ),
                ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.qr_code_scanner, color: Colors.blue)),
                  title: const Text('Scan Barcode'),
                  subtitle: const Text('Pakai kamera HP'),
                  onTap: () {
                    Navigator.pop(context);
                    bukaScanner();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const WorkflowsTab(),
      ItemsTab(products: products, loading: loadingProduk, onRefresh: fetchProducts),
      SearchTab(products: products, onScanTap: bukaScanner),
      const NotificationsTab(),
      const MenuTab(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.grey.shade100,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titles[currentIndex], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitles[currentIndex], style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
            Expanded(child: IndexedStack(index: currentIndex, children: tabs)),
          ],
        ),
      ),
      floatingActionButton: currentIndex == 1
          ? FloatingActionButton(
              onPressed: tampilkanPilihanTambah,
              backgroundColor: Colors.grey.shade700,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        selectedItemColor: Colors.grey.shade900,
        unselectedItemColor: Colors.grey.shade400,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.hub_outlined), label: 'Workflows'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Items'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
      ),
    );
  }
}

// ========================================================================
// TAB: WORKFLOWS
// ========================================================================

class WorkflowsTab extends StatelessWidget {
  const WorkflowsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _KartuWorkflow(
          icon: Icons.qr_code_scanner,
          judul: 'Scan & Catat Transaksi',
          deskripsi: 'Scan barcode atau input manual SKU untuk mencatat barang masuk/keluar.',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScannerPage()),
            );
          },
        ),
        const SizedBox(height: 12),
        _KartuWorkflow(
          icon: Icons.history,
          judul: 'Riwayat Transaksi',
          deskripsi: 'Lihat transaksi stok masuk/keluar yang sudah tercatat.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RiwayatStafPage()),
            );
          },
        ),
      ],
    );
  }
}

class _KartuWorkflow extends StatelessWidget {
  final IconData icon;
  final String judul;
  final String deskripsi;
  final VoidCallback onTap;

  const _KartuWorkflow({
    required this.icon,
    required this.judul,
    required this.deskripsi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.blue.shade50, child: Icon(icon, color: Colors.blue.shade700)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(deskripsi, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ========================================================================
// TAB: ITEMS
// ========================================================================

class ItemsTab extends StatelessWidget {
  final List products;
  final bool loading;
  final Future<void> Function() onRefresh;

  const ItemsTab({super.key, required this.products, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (loading && products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return Center(
        child: Text('Belum ada produk.', style: TextStyle(color: Colors.grey.shade400)),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = products[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.inventory_2, color: Colors.blue)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('SKU: ${item['sku']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                Text('${item['stok_saat_ini']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ========================================================================
// TAB: SEARCH
// ========================================================================

class SearchTab extends StatefulWidget {
  final List products;
  final VoidCallback onScanTap;

  const SearchTab({super.key, required this.products, required this.onScanTap});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final queryController = TextEditingController();
  String query = '';

  @override
  Widget build(BuildContext context) {
    final hasil = query.isEmpty
        ? []
        : widget.products.where((p) {
            final nama = p['nama'].toString().toLowerCase();
            final sku = p['sku'].toString().toLowerCase();
            final q = query.toLowerCase();
            return nama.contains(q) || sku.contains(q);
          }).toList();

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: queryController,
                onChanged: (v) => setState(() => query = v),
                decoration: InputDecoration(
                  hintText: 'Search items or SKU...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              if (query.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Enter text or scan to start your search.', style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                )
              else if (hasil.isEmpty)
                Expanded(
                  child: Center(child: Text('Tidak ditemukan.', style: TextStyle(color: Colors.grey.shade400))),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: hasil.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = hasil[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('SKU: ${item['sku']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('${item['stok_saat_ini']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'scan-search',
            backgroundColor: Colors.grey.shade700,
            onPressed: widget.onScanTap,
            child: const Icon(Icons.qr_code_scanner, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ========================================================================
// TAB: NOTIFICATIONS
// ========================================================================

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Belum ada notifikasi', style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// ========================================================================
// TAB: MENU
// ========================================================================

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  String nama = '';

  @override
  void initState() {
    super.initState();
    muatNama();
  }

  Future<void> muatNama() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nama = prefs.getString('nama') ?? 'Staf';
    });
  }

  String get inisial {
    if (nama.isEmpty) return '?';
    final kata = nama.trim().split(' ');
    if (kata.length == 1) return kata[0].substring(0, 1).toUpperCase();
    return (kata[0].substring(0, 1) + kata[1].substring(0, 1)).toUpperCase();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade700,
                child: Text(inisial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Staf Gudang', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: logout,
          ),
        ],
      ),
    );
  }
}

// ========================================================================
// RIWAYAT STAF PAGE
// ========================================================================

class RiwayatStafPage extends StatefulWidget {
  const RiwayatStafPage({super.key});

  @override
  State<RiwayatStafPage> createState() => _RiwayatStafPageState();
}

class _RiwayatStafPageState extends State<RiwayatStafPage> {
  List riwayat = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRiwayat();
  }

  Future<void> fetchRiwayat() async {
    final response = await http.get(Uri.parse('http://localhost:3000/transactions/recent'));
    setState(() {
      riwayat = jsonDecode(response.body);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : riwayat.isEmpty
              ? Center(child: Text('Belum ada transaksi.', style: TextStyle(color: Colors.grey.shade400)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: riwayat.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final t = riwayat[index];
                    final masuk = t['tipe'] == 'in';
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(masuk ? Icons.arrow_downward : Icons.arrow_upward, color: masuk ? Colors.green : Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t['nama'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${t['nama_staf']} • ${t['jumlah']} unit', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ========================================================================
// HELPER: cek SKU valid ke server
// ========================================================================

Future<String?> cariProdukValid(String skuInput) async {
  final response = await http.get(Uri.parse('http://localhost:3000/products'));
  final List produk = jsonDecode(response.body);

  final skuDicari = skuInput.trim().toUpperCase();

  for (final p in produk) {
    if (p['sku'].toString().toUpperCase() == skuDicari) {
      return p['sku'];
    }
  }
  return null;
}

// ========================================================================
// SCANNER PAGE
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
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InputManualPage()),
          );
          if (!mounted) return;
          Navigator.pop(context);
        },
        label: const Text('Input Manual'),
        icon: const Icon(Icons.keyboard),
      ),
    );
  }
}

// ========================================================================
// INPUT MANUAL PAGE
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TransaksiPage(sku: skuValid)),
    );

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
// TRANSAKSI PAGE
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
        Navigator.pop(context);
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