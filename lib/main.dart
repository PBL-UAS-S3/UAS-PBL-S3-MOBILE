import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

// ========================================================================
// API CONFIGURATION (PENGATURAN URL SERVER DINAMIS)
// ========================================================================

class ApiConfig {
  static String baseUrl = 'http://localhost:3000';

  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString('server_url') ?? 'http://localhost:3000';
  }

  static Future<void> setBaseUrl(String newUrl) async {
    String formatted = newUrl.trim();
    if (formatted.isNotEmpty) {
      if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
        formatted = 'http://$formatted';
      }
      if (formatted.endsWith('/')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
      baseUrl = formatted;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', baseUrl);
    }
  }
}

void showServerConfigDialog(BuildContext context, {VoidCallback? onSaved}) {
  final controller = TextEditingController(text: ApiConfig.baseUrl);
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Pengaturan URL Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan IP/URL Server Backend (contoh: http://localhost:3000 atau http://10.0.2.2:3000):',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'http://localhost:3000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiConfig.setBaseUrl(controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('URL Server disimpan: ${ApiConfig.baseUrl}')),
                );
              }
              if (onSaved != null) onSaved();
            },
            child: const Text('Simpan'),
          ),
        ],
      );
    },
  );
}

// Widget logo yang dipakai berulang — gambar kardus dari assets
class LogoStockin extends StatelessWidget {
  final double ukuran;
  const LogoStockin({super.key, this.ukuran = 90});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ukuran * 0.18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ukuran * 0.18),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.blue.shade50,
            child: const Center(child: Text('📦', style: TextStyle(fontSize: 40))),
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.loadBaseUrl();
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
      title: 'Stockin',
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
  bool obscurePassword = true;

  Future<void> login() async {
    setState(() {
      loading = true;
      pesanError = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
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
        pesanError = 'Gagal konek ke server (${ApiConfig.baseUrl}): $e';
      });
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            tooltip: 'Pengaturan Server',
            onPressed: () => showServerConfigDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: LogoStockin()),
              const SizedBox(height: 14),
              const Center(
                child: Text('Stockin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 18),
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
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  border: const UnderlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForgotPasswordPage(
                          initialEmail: emailController.text,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
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
  bool obscurePassword = true;

  Future<void> register() async {
    setState(() {
      loading = true;
      pesan = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register-staff'),
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
        pesan = 'Gagal konek ke server (${ApiConfig.baseUrl}): $e';
      });
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            tooltip: 'Pengaturan Server',
            onPressed: () => showServerConfigDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: LogoStockin()),
              const SizedBox(height: 14),
              const Center(
                child: Text('Stockin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 18),
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
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  border: const UnderlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
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
// FORGOT PASSWORD PAGE
// ========================================================================

class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final TextEditingController emailController;
  String pesan = '';
  bool sukses = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> kirimReset() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        sukses = false;
        pesan = 'Silakan masukkan alamat email Anda';
      });
      return;
    }

    setState(() {
      loading = true;
      pesan = '';
    });

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      loading = false;
      sukses = true;
      pesan = 'Tautan atau instruksi pemulihan kata sandi telah dikirim ke $email. Silakan periksa kotak masuk atau hubungi manajer gudang.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('🔐', style: TextStyle(fontSize: 40))),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Forgot Password?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'Masukkan email akun Anda untuk mendapatkan tautan pemulihan kata sandi.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 28),

              const Text('Email', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Enter your registered email',
                  border: UnderlineInputBorder(),
                ),
              ),

              if (pesan.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sukses ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pesan,
                    style: TextStyle(
                      color: sukses ? Colors.green.shade700 : Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : kirimReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Back to Sign in',
                    style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.bold),
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
// MAIN SHELL — bottom nav 3 tab
// ========================================================================

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;
  List products = [];
  bool loadingProduk = true;

  final titles = ['Items', 'Search', 'Menu'];
  final subtitles = [
    'Daftar produk gudang',
    'Cari produk atau scan',
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
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/products'));
      if (response.statusCode == 200) {
        setState(() {
          products = jsonDecode(response.body);
        });
      }
    } catch (e) {
      // biarkan tetap list kosong jika gagal
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
      ItemsTab(products: products, loading: loadingProduk, onRefresh: fetchProducts),
      SearchTab(products: products, onScanTap: bukaScanner),
      MenuTab(onUrlChanged: fetchProducts),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.grey.shade100,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      LogoStockin(ukuran: 28),
                      const SizedBox(width: 8),
                      const Text('Stockin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
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
      floatingActionButton: currentIndex == 0
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
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Items'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
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
        child: Text('Belum ada produk atau gagal terhubung ke server.', style: TextStyle(color: Colors.grey.shade400)),
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
                      Text(item['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('SKU: ${item['sku'] ?? '-'}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                Text('${item['stok_saat_ini'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            final nama = (p['nama'] ?? '').toString().toLowerCase();
            final sku = (p['sku'] ?? '').toString().toLowerCase();
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
                                  Text(item['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('SKU: ${item['sku'] ?? '-'}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('${item['stok_saat_ini'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
// TAB: MENU
// ========================================================================

class MenuTab extends StatefulWidget {
  final VoidCallback? onUrlChanged;
  const MenuTab({super.key, this.onUrlChanged});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  String nama = '';

  String? namaGudang;
  String? alamatGudang;
  String? teleponGudang;
  double? latGudang;
  double? lonGudang;
  bool loadingAlamat = true;

  @override
  void initState() {
    super.initState();
    muatNama();
    muatAlamatGudang();
  }

  Future<void> muatNama() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nama = prefs.getString('nama') ?? 'Staf';
    });
  }

  Future<void> muatAlamatGudang() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/pengaturan'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          namaGudang = data['nama_gudang'];
          alamatGudang = data['alamat'];
          teleponGudang = data['telepon'];
          latGudang = data['latitude'] != null ? double.tryParse(data['latitude'].toString()) : null;
          lonGudang = data['longitude'] != null ? double.tryParse(data['longitude'].toString()) : null;
        });
      }
    } catch (e) {
      // biarkan kosong jika gagal, kartu akan menampilkan pesan belum tersedia
    }
    setState(() => loadingAlamat = false);
  }

  Future<void> bukaDiMaps() async {
    if (latGudang == null || lonGudang == null) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latGudang,$lonGudang');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
    return SingleChildScrollView(
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
          const SizedBox(height: 20),

          // Kartu Alamat Gudang (read-only, hanya Manager yang bisa ubah lewat web)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(14),
            ),
            child: loadingAlamat
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.deepOrange.shade400, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            namaGudang != null && namaGudang!.isNotEmpty ? namaGudang! : 'Alamat Gudang',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (alamatGudang != null && alamatGudang!.isNotEmpty)
                            ? alamatGudang!
                            : 'Alamat belum diatur oleh Manager.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      if (teleponGudang != null && teleponGudang!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Telepon: $teleponGudang', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                      if (latGudang != null && lonGudang != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: bukaDiMaps,
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('Buka di Google Maps'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepOrange.shade400,
                              side: BorderSide(color: Colors.deepOrange.shade200),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.blue),
            title: const Text('Profil Saya'),
            subtitle: const Text('Ubah nama, telepon, dan password'),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilStafPage()),
              );
              muatNama();
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.blue),
            title: const Text('Riwayat Transaksi'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RiwayatStafPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.teal),
            title: const Text('Pusat Bantuan (FAQ)'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BantuanPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline, color: Colors.teal),
            title: const Text('Hubungi Kami'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HubungiKamiPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: Colors.teal),
            title: const Text('Ketentuan & Kebijakan'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KetentuanPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dns, color: Colors.orange),
            title: const Text('Ubah URL Server'),
            subtitle: Text(ApiConfig.baseUrl, style: const TextStyle(fontSize: 12)),
            onTap: () {
              showServerConfigDialog(
                context,
                onSaved: () {
                  setState(() {});
                  if (widget.onUrlChanged != null) widget.onUrlChanged!();
                  muatAlamatGudang();
                },
              );
            },
          ),
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
// PROFIL STAF PAGE
// ========================================================================

class ProfilStafPage extends StatefulWidget {
  const ProfilStafPage({super.key});

  @override
  State<ProfilStafPage> createState() => _ProfilStafPageState();
}

class _ProfilStafPageState extends State<ProfilStafPage> {
  final namaController = TextEditingController();
  final teleponController = TextEditingController();
  String email = '';

  final passwordLamaController = TextEditingController();
  final passwordBaruController = TextEditingController();
  final konfirmasiController = TextEditingController();

  bool loading = true;
  bool savingProfil = false;
  bool savingPassword = false;
  String pesanProfil = '';
  String suksesProfil = '';
  String pesanPassword = '';
  String suksesPassword = '';

  @override
  void initState() {
    super.initState();
    muatProfil();
  }

  Future<String?> ambilToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> muatProfil() async {
    setState(() => loading = true);
    try {
      final token = await ambilToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/profil'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        namaController.text = data['nama'] ?? '';
        teleponController.text = data['telepon'] ?? '';
        setState(() => email = data['email'] ?? '');
      }
    } catch (e) {
      // biarkan kosong jika gagal
    }
    setState(() => loading = false);
  }

  Future<void> simpanProfil() async {
    setState(() {
      savingProfil = true;
      pesanProfil = '';
      suksesProfil = '';
    });
    try {
      final token = await ambilToken();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/profil'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'nama': namaController.text, 'telepon': teleponController.text}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nama', namaController.text);
        setState(() => suksesProfil = 'Profil berhasil disimpan');
      } else {
        setState(() => pesanProfil = data['error'] ?? 'Gagal menyimpan profil');
      }
    } catch (e) {
      setState(() => pesanProfil = 'Tidak dapat terhubung ke server');
    }
    setState(() => savingProfil = false);
  }

  Future<void> simpanPassword() async {
    setState(() {
      pesanPassword = '';
      suksesPassword = '';
    });

    if (passwordLamaController.text.isEmpty ||
        passwordBaruController.text.isEmpty ||
        konfirmasiController.text.isEmpty) {
      setState(() => pesanPassword = 'Semua kolom wajib diisi');
      return;
    }
    if (passwordBaruController.text.length < 6) {
      setState(() => pesanPassword = 'Password baru minimal 6 karakter');
      return;
    }
    if (passwordBaruController.text != konfirmasiController.text) {
      setState(() => pesanPassword = 'Konfirmasi password tidak sama');
      return;
    }

    setState(() => savingPassword = true);
    try {
      final token = await ambilToken();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/ganti-password'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'password_lama': passwordLamaController.text,
          'password_baru': passwordBaruController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() => suksesPassword = 'Password berhasil diubah');
        passwordLamaController.clear();
        passwordBaruController.clear();
        konfirmasiController.clear();
      } else {
        setState(() => pesanPassword = data['error'] ?? 'Gagal mengubah password');
      }
    } catch (e) {
      setState(() => pesanPassword = 'Tidak dapat terhubung ke server');
    }
    setState(() => savingPassword = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Data Diri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Nama Lengkap', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  TextField(controller: namaController, decoration: const InputDecoration(border: UnderlineInputBorder())),
                  const SizedBox(height: 14),
                  const Text('Email', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
                    child: Text(email, style: TextStyle(color: Colors.grey.shade600)),
                  ),
                  const SizedBox(height: 14),
                  const Text('Nomor Telepon', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  TextField(
                    controller: teleponController,
                    decoration: const InputDecoration(hintText: '08xx-xxxx-xxxx', border: UnderlineInputBorder()),
                  ),

                  if (pesanProfil.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(pesanProfil, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  if (suksesProfil.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(suksesProfil, style: const TextStyle(color: Colors.green, fontSize: 13)),
                  ],

                  const SizedBox(height: 18),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: savingProfil ? null : simpanProfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(savingProfil ? 'Menyimpan...' : 'Simpan Perubahan'),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('Ganti Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  const Text('Password Lama', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  TextField(controller: passwordLamaController, obscureText: true, decoration: const InputDecoration(border: UnderlineInputBorder())),
                  const SizedBox(height: 14),
                  const Text('Password Baru', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  TextField(controller: passwordBaruController, obscureText: true, decoration: const InputDecoration(hintText: 'Minimal 6 karakter', border: UnderlineInputBorder())),
                  const SizedBox(height: 14),
                  const Text('Konfirmasi Password Baru', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  TextField(controller: konfirmasiController, obscureText: true, decoration: const InputDecoration(border: UnderlineInputBorder())),

                  if (pesanPassword.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(pesanPassword, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  if (suksesPassword.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(suksesPassword, style: const TextStyle(color: Colors.green, fontSize: 13)),
                  ],

                  const SizedBox(height: 18),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: savingPassword ? null : simpanPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(savingPassword ? 'Menyimpan...' : 'Ubah Password'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ========================================================================
// PUSAT BANTUAN (FAQ) PAGE
// ========================================================================

class BantuanPage extends StatelessWidget {
  const BantuanPage({super.key});

  static const List<Map<String, String>> faq = [
    {
      'q': 'Bagaimana cara mencatat barang masuk/keluar?',
      'a': 'Buka tab Items, tekan tombol "+", lalu pilih Scan Barcode atau Input Manual, masukkan jumlah dan jenis transaksi (masuk/keluar), lalu simpan.',
    },
    {
      'q': 'Kenapa SKU saya dibilang tidak ditemukan?',
      'a': 'Pastikan SKU yang di-scan/ketik sudah terdaftar di Master Data oleh Manager. Coba refresh daftar produk di tab Items dengan menarik layar ke bawah.',
    },
    {
      'q': 'Apakah saya bisa mengedit atau menghapus produk?',
      'a': 'Tidak. Mengubah atau menghapus data produk hanya bisa dilakukan Manager lewat web dashboard.',
    },
    {
      'q': 'Lupa password, bagaimana solusinya?',
      'a': 'Fitur reset password mandiri untuk akun Staf belum tersedia. Hubungi Manager gudang kamu untuk dibantu reset.',
    },
    {
      'q': 'Kenapa aplikasi mobile ini tidak bisa menambah produk baru?',
      'a': 'Karena aplikasi mobile memang khusus untuk pencatatan transaksi oleh Staf. Penambahan produk baru dilakukan Manager lewat web dashboard.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pusat Bantuan')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: faq.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = faq[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(item['q']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['a']!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ========================================================================
// HUBUNGI KAMI PAGE
// ========================================================================

class HubungiKamiPage extends StatefulWidget {
  const HubungiKamiPage({super.key});

  @override
  State<HubungiKamiPage> createState() => _HubungiKamiPageState();
}

class _HubungiKamiPageState extends State<HubungiKamiPage> {
  final pesanController = TextEditingController();
  bool loading = false;
  String pesanError = '';
  String sukses = '';

  Future<void> kirim() async {
    setState(() {
      pesanError = '';
      sukses = '';
    });

    if (pesanController.text.trim().isEmpty) {
      setState(() => pesanError = 'Pesan tidak boleh kosong');
      return;
    }

    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/keluhan'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'pesan': pesanController.text}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        setState(() {
          sukses = data['message'] ?? 'Pesan berhasil dikirim';
          pesanController.clear();
        });
      } else {
        setState(() => pesanError = data['error'] ?? 'Gagal mengirim pesan');
      }
    } catch (e) {
      setState(() => pesanError = 'Tidak dapat terhubung ke server');
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hubungi Kami')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Laporkan kendala, bug, atau masukan untuk tim kami.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: pesanController,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Jelaskan kendala yang kamu alami...',
              ),
            ),
            if (pesanError.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(pesanError, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            if (sukses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(sukses, style: const TextStyle(color: Colors.green, fontSize: 13)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: loading ? null : kirim,
                icon: const Icon(Icons.send, size: 18),
                label: Text(loading ? 'Mengirim...' : 'Kirim Pesan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================================================
// KETENTUAN & KEBIJAKAN PAGE
// ========================================================================

class KetentuanPage extends StatefulWidget {
  const KetentuanPage({super.key});

  @override
  State<KetentuanPage> createState() => _KetentuanPageState();
}

class _KetentuanPageState extends State<KetentuanPage> {
  bool tabPrivasi = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ketentuan & Kebijakan')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Kebijakan Privasi'),
                    selected: tabPrivasi,
                    onSelected: (v) => setState(() => tabPrivasi = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Syarat Ketentuan'),
                    selected: !tabPrivasi,
                    onSelected: (v) => setState(() => tabPrivasi = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  tabPrivasi
                      ? '1. Data yang Dikumpulkan.\nStockin menyimpan data akun (nama, email, nomor telepon), data produk, dan riwayat transaksi gudang yang kamu masukkan ke dalam sistem.\n\n'
                        '2. Penggunaan Data.\nData digunakan untuk menjalankan fitur aplikasi, termasuk analisis AI Insight untuk rekomendasi restock. Data tidak dibagikan ke pihak ketiga di luar kebutuhan sistem (seperti Gemini API untuk analisis AI).\n\n'
                        '3. Keamanan Data.\nPassword disimpan dalam bentuk terenkripsi (hash), dan akses ke data dibatasi berdasarkan peran (Manager/Staf).\n\n'
                        '4. Perubahan Kebijakan.\nKebijakan ini dapat berubah sewaktu-waktu sesuai kebutuhan pengembangan aplikasi.'
                      : '1. Penggunaan Layanan.\nAplikasi ini disediakan untuk membantu pengelolaan inventori gudang. Akun Manager bertanggung jawab atas keakuratan data yang dimasukkan.\n\n'
                        '2. Peran Pengguna.\nAkun Manager hanya dapat diakses lewat web, dan akun Staf Gudang hanya dapat diakses lewat aplikasi mobile.\n\n'
                        '3. Rekomendasi AI.\nRekomendasi restock dari AI bersifat saran berdasarkan data historis, keputusan akhir pembelian tetap berada di tangan Manager.\n\n'
                        '4. Batasan Tanggung Jawab.\nPengembang tidak bertanggung jawab atas kerugian yang timbul dari kesalahan input data oleh pengguna.',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
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
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/transactions/recent'));
      if (response.statusCode == 200) {
        setState(() {
          riwayat = jsonDecode(response.body);
        });
      }
    } catch (e) {
      // biarkan riwayat kosong
    }
    setState(() {
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
                                Text(t['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${t['nama_staf'] ?? '-'} • ${t['jumlah'] ?? 0} unit', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
  try {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/products'));
    if (response.statusCode == 200) {
      final List produk = jsonDecode(response.body);
      final skuDicari = skuInput.trim().toUpperCase();

      for (final p in produk) {
        if (p['sku'].toString().toUpperCase() == skuDicari) {
          return p['sku'];
        }
      }
    }
  } catch (e) {
    // Return null jika ada kendala jaringan
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
        Uri.parse('${ApiConfig.baseUrl}/transactions'),
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
        pesan = 'Tidak dapat terhubung ke server (${ApiConfig.baseUrl}): $e';
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