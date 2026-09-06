import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';

class AnimatedNavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AnimatedNavItemData({
    required this.icon,
    required this.activeIcon,
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
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = selectedIndex == index;

          return _AnimatedNavItem(
            data: item,
            isSelected: isSelected,
            onTap: () {
              if (!isSelected) {
                HapticFeedback.selectionClick();
                onItemSelected(index);
              }
            },
          );
        }),
      ),
    );
  }
}

class _AnimatedNavItem extends StatefulWidget {
  final AnimatedNavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.08)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_controller);

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.06, end: 0.06)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.06, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);

    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primaryLight;
    final inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: AppColors.primary.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppColors.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = widget.isSelected
                    ? _scaleAnimation.value
                    : 1.0;
                final rotation = widget.isSelected
                    ? _rotationAnimation.value
                    : 0.0;

                return Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Icon(
                      widget.isSelected
                          ? widget.data.activeIcon
                          : widget.data.icon,
                      color: widget.isSelected ? activeColor : inactiveColor,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    widget.isSelected ? FontWeight.bold : FontWeight.w500,
                color: widget.isSelected ? activeColor : inactiveColor,
                fontFamily: 'Roboto',
              ),
              child: Text(
                widget.data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            // Animated indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: widget.isSelected ? 5 : 0,
              height: widget.isSelected ? 5 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.8),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
