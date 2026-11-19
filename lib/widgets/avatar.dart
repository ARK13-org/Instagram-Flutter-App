import 'package:flutter/material.dart';
import 'package:instagram_ui/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.username,
    this.size = 40,
    this.ring = false,
    this.onTap,
  });

  final String username;
  final double size;

  /// Instagram-style gradient ring around the avatar.
  final bool ring;
  final VoidCallback? onTap;

  Color get _color {
    final hash = username.codeUnits.fold<int>(
      7,
      (a, b) => (a * 31 + b) & 0x7fffffff,
    );
    return Brand.avatarColors[hash % Brand.avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final initial = username.isEmpty ? '?' : username[0].toUpperCase();
    final base = _color;

    Widget face = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.25), base),
          ],
        ),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
        ),
      ),
    );

    if (ring) {
      face = Container(
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: Brand.gradient,
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: face,
        ),
      );
    }

    if (onTap == null) return face;
    return GestureDetector(onTap: onTap, child: face);
  }
}
