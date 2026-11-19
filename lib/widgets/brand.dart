import 'package:flutter/material.dart';
import 'package:instagram_ui/theme/app_theme.dart';

class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => Brand.gradient.createShader(
        Rect.fromLTWH(0, 0, rect.width, rect.height),
      ),
      child: Text(text, style: style),
    );
  }
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    return GradientText(
      'ARK13',
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: Colors.white,
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled || loading ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: Brand.gradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded, borderless, filled text-field style used across the app.
InputDecoration fieldDecoration(
  BuildContext context, {
  String? label,
  String? hint,
  IconData? icon,
  Widget? suffix,
  String? counter,
}) {
  final cs = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color c, [double w = 0]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    counterText: counter,
    prefixIcon: icon == null ? null : Icon(icon, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(cs.outline),
    enabledBorder: border(cs.outline),
    focusedBorder: border(cs.primary, 1.5),
    errorBorder: border(cs.error, 1.2),
    focusedErrorBorder: border(cs.error, 1.5),
  );
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ),
  );
}
