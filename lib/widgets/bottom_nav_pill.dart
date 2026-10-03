import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomNavPill extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavPill({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    {'icon': Icons.inventory_2_outlined, 'label': 'Items'},
    {'icon': Icons.search, 'label': 'Search'},
    {'icon': Icons.menu, 'label': 'Menu'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final aktif = i == currentIndex;
            final item = _items[i];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: aktif ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item['icon'] as IconData, size: 20, color: aktif ? Colors.white : AppColors.textGrey),
                    if (aktif) ...[
                      const SizedBox(width: 6),
                      Text(item['label'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}