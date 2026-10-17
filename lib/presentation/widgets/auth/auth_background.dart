import 'package:flutter/material.dart';
import 'package:toktok/config/theme/app_colors.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -120,
          child: _glow(AppColors.magenta.withValues(alpha: 0.18), 360),
        ),
        Positioned(
          bottom: -140,
          right: -140,
          child: _glow(AppColors.orange.withValues(alpha: 0.16), 380),
        ),
      ],
    );
  }

  Widget _glow(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      );
}

class AuthLogo extends StatelessWidget {
  final double size;
  const AuthLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final inner = size * 0.66;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(size * 0.29),
        border: Border.all(color: Colors.white),
        boxShadow: AppColors.brandGlow,
      ),
      child: Center(
        child: Container(
          width: inner,
          height: inner,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(inner * 0.31),
          ),
          child: Center(
            child: Container(
              width: inner * 0.6,
              height: inner * 0.6,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1020),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: AppColors.magenta,
                size: inner * 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}