import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tekan_skala.dart';
import 'tabs/items_tab.dart';
import 'tabs/menu_tab.dart';
import 'tabs/search_tab.dart';
import 'transactions/input_manual_page.dart';
import 'transactions/scanner_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;
  List products = [];
  bool loadingProduk = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() => loadingProduk = true);
    try {
      final hasil = await ProductService.fetchProducts();
      setState(() => products = hasil);
    } catch (_) {
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

  void _pilihTab(int i) {
    if (i == currentIndex) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => currentIndex = i);
  }

  Widget _itemNav(int index, IconData ikon, IconData ikonAktif, String label) {
    final aktif = currentIndex == index;
    final warna = aktif ? AppColors.primary : AppColors.textGrey;
    const durasi = Duration(milliseconds: 220);

    return Expanded(
      child: TekanSkala(
        skala: 0.9,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _pilihTab(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: aktif ? 1.12 : 1.0,
                duration: durasi,
                curve: Curves.easeOutBack,
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: warna),
                  duration: durasi,
                  builder: (context, c, _) =>
                      Icon(aktif ? ikonAktif : ikon, size: 22, color: c),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: durasi,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                  color: warna,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navbar kaca: ramping, buram, pil penanda meluncur antartab
  Widget _navKaca() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(44, 0, 44, 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.68),
                        Colors.white.withOpacity(0.38),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.85),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // pil penanda yang meluncur
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment(currentIndex - 1.0, 0),
                        child: FractionallySizedBox(
                          widthFactor: 1 / 3,
                          heightFactor: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _itemNav(0, Icons.inventory_2_outlined, Icons.inventory_2, 'Barang'),
                          _itemNav(1, Icons.search, Icons.search, 'Cari'),
                          _itemNav(2, Icons.menu, Icons.menu, 'Menu'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Semua tab tetap hidup (state terjaga), yang aktif memudar masuk
  Widget _tabAnimasi(int i, Widget tab) {
    final aktif = currentIndex == i;
    final arah = i < currentIndex ? -0.04 : 0.04;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !aktif,
        child: AnimatedSlide(
          offset: aktif ? Offset.zero : Offset(arah, 0),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: aktif ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: tab,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ItemsTab(
        products: products,
        loading: loadingProduk,
        onRefresh: fetchProducts,
        onScanTap: bukaScanner,
      ),
      SearchTab(
        products: products,
        onScanTap: bukaScanner,
        onInputManualTap: bukaInputManual,
      ),
      const MenuTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  for (int i = 0; i < tabs.length; i++) _tabAnimasi(i, tabs[i]),
                ],
              ),
            ),
          ),
          _navKaca(),
        ],
      ),
    );
  }
}