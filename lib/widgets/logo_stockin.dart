import 'package:flutter/material.dart';

class LogoStockin extends StatelessWidget {
  final double ukuran;
  const LogoStockin({super.key, this.ukuran = 90});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ukuran * 0.18),
      child: Image.asset(
        'assets/images/logo.png',
        width: ukuran,
        height: ukuran,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: ukuran,
          height: ukuran,
          color: Colors.orange.shade50,
          child: const Center(child: Text('📦', style: TextStyle(fontSize: 40))),
        ),
      ),
    );
  }
}