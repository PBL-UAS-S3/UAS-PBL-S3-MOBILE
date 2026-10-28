import 'package:flutter/material.dart';

/// Membungkus widget apa pun supaya mengecil sebentar saat disentuh.
/// Tidak mengganggu onTap/onPressed milik widget di dalamnya.
class TekanSkala extends StatefulWidget {
  final Widget child;
  final double skala;

  const TekanSkala({super.key, required this.child, this.skala = 0.96});

  @override
  State<TekanSkala> createState() => _TekanSkalaState();
}

class _TekanSkalaState extends State<TekanSkala> {
  bool _ditekan = false;

  void _atur(bool nilai) {
    if (_ditekan != nilai && mounted) setState(() => _ditekan = nilai);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _atur(true),
      onPointerUp: (_) => _atur(false),
      onPointerCancel: (_) => _atur(false),
      child: AnimatedScale(
        scale: _ditekan ? widget.skala : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}