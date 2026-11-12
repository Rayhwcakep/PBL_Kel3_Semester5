import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Gaya tombol pill Scoutify.
enum PillButtonVariant { primary, secondary, lime }

/// Tombol berbentuk pill penuh dengan animasi mikro sentuhan cepat (60ms).
class PillButton extends StatefulWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = PillButtonVariant.primary,
    this.expand = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final PillButtonVariant variant;
  final bool expand;
  final double height;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (widget.variant) {
      PillButtonVariant.primary => (
        AppColors.lime,
        AppColors.onAccent,
        Colors.transparent,
      ),
      PillButtonVariant.secondary => (
        AppColors.surface,
        AppColors.ink,
        AppColors.cardBorder,
      ),
      PillButtonVariant.lime => (
        AppColors.lime,
        AppColors.onAccent,
        Colors.transparent,
      ),
    };

    final child = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: foreground),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMd(color: foreground),
          ),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(widget.trailingIcon, size: 18, color: foreground),
        ],
      ],
    );

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 15),
      curve: Curves.easeOutQuad,
      child: SizedBox(
        height: widget.height,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.pillBorder,
            side: BorderSide(color: border, width: 1.5),
          ),
          child: InkWell(
            onTap: widget.onPressed,
            onTapDown: widget.onPressed == null
                ? null
                : (_) => setState(() => _isPressed = true),
            onTapUp: widget.onPressed == null
                ? null
                : (_) => setState(() => _isPressed = false),
            onTapCancel: widget.onPressed == null
                ? null
                : () => setState(() => _isPressed = false),
            borderRadius: AppRadius.pillBorder,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol ikon bulat 44x44 dengan animasi mikro sentuhan cepat (60ms).
class CircleIconButton extends StatefulWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.background,
    this.foreground,
    this.size = 44,
    this.showBorder = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? background;
  final Color? foreground;
  final double size;
  final bool showBorder;

  @override
  State<CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<CircleIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 15),
      curve: Curves.easeOutQuad,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Material(
          color: widget.background ?? AppColors.surface,
          shape: CircleBorder(
            side: BorderSide(
              color: widget.showBorder
                  ? AppColors.cardBorder
                  : Colors.transparent,
            ),
          ),
          child: InkWell(
            onTap: widget.onPressed,
            onTapDown: widget.onPressed == null
                ? null
                : (_) => setState(() => _isPressed = true),
            onTapUp: widget.onPressed == null
                ? null
                : (_) => setState(() => _isPressed = false),
            onTapCancel: widget.onPressed == null
                ? null
                : () => setState(() => _isPressed = false),
            customBorder: const CircleBorder(),
            child: Icon(
              widget.icon,
              size: widget.size * 0.45,
              color: widget.foreground ?? AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
