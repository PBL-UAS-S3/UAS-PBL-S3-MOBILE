import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/logo_stockin.dart';

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
        setState(() => pesan = data['error'] ?? 'Registrasi gagal');
      }
    } catch (e) {
      setState(() => pesan = 'Gagal konek ke server (${ApiConfig.baseUrl}): $e');
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              const SizedBox(height: 24),
              const Text('Create an account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Get started for free today..', style: TextStyle(color: Colors.grey.shade600)),
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
                    icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade600),
                    onPressed: () => setState(() => obscurePassword = !obscurePassword),
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
                    color: sukses ? AppColors.successBg : AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(pesan, style: TextStyle(color: sukses ? AppColors.success : AppColors.danger, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
                          child: Text('Sign in', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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