import 'package:dudulan/k/app_s/aps.dart';
import 'package:dudulan/k/navigtion.dart';
import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final List<NavigationItem> navigationItems;
  final ColorScheme colorScheme;

  const BottomNav({
    super.key,
    required this.navigationItems,
    required this.colorScheme,
  });

  @override
  BottomNavigationBar build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: colorScheme.surfaceContainerLow,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      showUnselectedLabels: true,
      items:
          navigationItems
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                ),
              )
              .toList(),
      currentIndex: Aps().selectedIndex.watch(context),
      onTap: (index) {
        Aps().selectedIndex.set(index);
      },
    );
  }
}
