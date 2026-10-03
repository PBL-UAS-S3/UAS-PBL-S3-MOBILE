import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

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
      backgroundColor: Colors.white,
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
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(16)),
                  child: const Center(child: Text('🔐', style: TextStyle(fontSize: 40))),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Forgot Password?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Masukkan email akun Anda untuk mendapatkan tautan pemulihan kata sandi.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 28),
              const Text('Email', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Enter your registered email', border: UnderlineInputBorder()),
              ),
              if (pesan.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sukses ? AppColors.successBg : AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(pesan, style: TextStyle(color: sukses ? AppColors.success : AppColors.danger, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : kirimReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Back to Sign in', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}