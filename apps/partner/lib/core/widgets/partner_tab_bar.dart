import 'package:flutter/material.dart';
import 'package:kaylo_ui/widgets/liquid_tab_bar.dart';

class PartnerTabItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badgeCount;
  const PartnerTabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

class PartnerTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<PartnerTabItem> items;
  const PartnerTabBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.items,
  });
  @override
  Widget build(BuildContext context) => LiquidTabBar(
    index: currentIndex,
    onSelected: onSelected,
    labels: [for (final i in items) i.label],
    icons: [for (final i in items) i.icon],
    selectedIcons: [for (final i in items) i.selectedIcon],
    badgeCounts: [for (final i in items) i.badgeCount],
  );
}
