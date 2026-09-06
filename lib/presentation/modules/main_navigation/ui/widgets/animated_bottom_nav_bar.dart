import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';
import 'rive_animated_icons.dart';

class AnimatedNavItemData {
  final RiveNavTab tab;
  final String label;

  const AnimatedNavItemData({
    required this.tab,
    required this.label,
  });
}

class AnimatedBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<AnimatedNavItemData> items;

  const AnimatedBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = selectedIndex == index;

          return Expanded(
            child: _AnimatedNavItem(
              data: item,
              isSelected: isSelected,
              onTap: () {
                if (!isSelected) {
                  HapticFeedback.selectionClick();
                  onItemSelected(index);
                }
              },
            ),
          );
        }),
      ),
    );
  }
}

class _AnimatedNavItem extends StatelessWidget {
  final AnimatedNavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primaryLight;
    final inactiveColor = isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: AppColors.primary.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryLight.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rive-style Dynamic Animated Micro-Vector Icon
            RiveNavIcon(
              tab: data.tab,
              isSelected: isSelected,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
            ),
            const SizedBox(height: 4),
            // Smoothly switch: Text label for unselected tabs, glowing neon dot for selected tab
            SizedBox(
              height: 16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: isSelected
                    ? Container(
                        key: const ValueKey('indicator_dot'),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.8),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      )
                    : Text(
                        data.label,
                        key: ValueKey('label_${data.label}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: inactiveColor,
                          fontFamily: 'Roboto',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
