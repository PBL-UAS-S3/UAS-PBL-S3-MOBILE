import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_pill.dart';
import 'products/barang_rusak_page.dart';
import 'tabs/items_tab.dart';
import 'tabs/search_tab.dart';
import 'tabs/menu_tab.dart';
import 'transactions/scanner_page.dart';
import 'transactions/input_manual_page.dart';

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
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerPage()));
    fetchProducts();
  }

  Future<void> bukaInputManual() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const InputManualPage()));
    fetchProducts();
  }

  Future<void> bukaBarangRusak() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const BarangRusakPage()));
    fetchProducts();
  }

  void tampilkanPilihanTambah() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AKSI INVENTORI GUDANG',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: CircleAvatar(backgroundColor: AppColors.primarySoft, child: const Icon(Icons.keyboard, color: AppColors.primary)),
                  title: const Text('Input Manual'),
                  subtitle: const Text('Ketik SKU untuk catat transaksi'),
                  onTap: () {
                    Navigator.pop(context);
                    bukaInputManual();
                  },
                ),
                ListTile(
                  leading: CircleAvatar(backgroundColor: AppColors.primarySoft, child: const Icon(Icons.qr_code_scanner, color: AppColors.primary)),
                  title: const Text('Scan Barcode'),
                  subtitle: const Text('Pakai kamera HP scan barcode SKU'),
                  onTap: () {
                    Navigator.pop(context);
                    bukaScanner();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFFFECEC), child: Icon(Icons.build_circle_outlined, color: Colors.red)),
                  title: const Text('Kelola Barang Rusak Tersortir'),
                  subtitle: const Text('Pemisahan, sortir, afkir, atau pulihkan barang cacat'),
                  onTap: () {
                    Navigator.pop(context);
                    bukaBarangRusak();
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
      ItemsTab(products: products, loading: loadingProduk, onRefresh: fetchProducts, onTambah: tampilkanPilihanTambah),
      SearchTab(products: products, onScanTap: bukaScanner),
      const MenuTab(),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: currentIndex, children: tabs)),
      bottomNavigationBar: BottomNavPill(currentIndex: currentIndex, onTap: (i) => setState(() => currentIndex = i)),
    );
  }
}