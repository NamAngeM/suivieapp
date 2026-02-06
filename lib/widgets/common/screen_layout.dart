import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Gradient background container used across screens
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool showWatermark;

  const GradientBackground({
    super.key,
    required this.child,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F9FA), Color(0xFFF0F4F8)],
        ),
      ),
      child: Stack(
        children: [
          if (showWatermark)
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.03,
                  child: Icon(
                    Icons.church,
                    size: 300,
                    color: AppTheme.zoeBlue,
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Custom screen header with gradient background
class ScreenHeader extends StatelessWidget {
  final String title;
  final Widget? subtitle;
  final Widget? action;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B365D).withValues(alpha: 0.1),
            const Color(0xFFB41E3A).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B365D),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 16),
            subtitle!,
          ],
        ],
      ),
    );
  }
}
