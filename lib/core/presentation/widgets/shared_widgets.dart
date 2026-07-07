import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system.dart';

class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final bool isCompact;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? AppDesign.space12 : AppDesign.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: TextStyle(fontSize: isCompact ? 36 : 64)),
            SizedBox(height: isCompact ? AppDesign.space8 : AppDesign.space16),
            Text(
              title,
              style: TextStyle(
                fontSize: isCompact ? 14 : 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isCompact ? 4 : AppDesign.space8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isCompact ? 11 : 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              SizedBox(height: isCompact ? AppDesign.space12 : AppDesign.space20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isFullWidth;
  final bool isSecondary;
  final bool isCompact;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.isFullWidth = false,
    this.isSecondary = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = backgroundColor ?? AppDesign.primaryEmerald;
    final textCol = foregroundColor ?? Colors.white;

    final Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: isCompact ? 14 : 18),
          SizedBox(width: isCompact ? 4 : AppDesign.space8),
        ],
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isCompact ? 12 : 14,
          ),
        ),
      ],
    );

    final buttonStyle = isSecondary
        ? OutlinedButton.styleFrom(
            foregroundColor: backgroundColor ?? AppDesign.primaryEmerald,
            side: BorderSide(
              color: backgroundColor ?? AppDesign.primaryEmerald,
              width: 1.5,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? AppDesign.space12 : AppDesign.space20,
              vertical: isCompact ? AppDesign.space8 : AppDesign.space12,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: textCol,
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? AppDesign.space12 : AppDesign.space20,
              vertical: isCompact ? AppDesign.space8 : AppDesign.space12,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
          );

    final widget = isSecondary
        ? OutlinedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: buttonChild,
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: buttonChild,
          );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: widget);
    }
    return widget;
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final bool obscureText;
  final TextInputType keyboardType;
  final int? maxLength;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;

  const AppTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        helperMaxLines: 2,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppDesign.primaryTeal, size: 20)
            : null,
        suffixIcon: suffixIcon,
        counterText: '',
        filled: true,
        fillColor: isDark ? AppDesign.darkCard : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesign.space16,
          vertical: AppDesign.space16,
        ),
        border: OutlineInputBorder(
          borderRadius: AppDesign.borderMedium,
          borderSide: BorderSide(
            color: isDark ? AppDesign.darkBorder : AppDesign.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDesign.borderMedium,
          borderSide: BorderSide(
            color: isDark
                ? AppDesign.darkBorder.withValues(alpha: 0.5)
                : AppDesign.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDesign.borderMedium,
          borderSide: const BorderSide(
            color: AppDesign.primaryEmerald,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDesign.borderMedium,
          borderSide: const BorderSide(color: AppDesign.redPayable, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDesign.borderMedium,
          borderSide: const BorderSide(color: AppDesign.redPayable, width: 2),
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
          fontSize: 11,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.grey.shade900,
            letterSpacing: -0.3,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// 1. Shimmer Placeholder
class ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: [0.0, _controller.value, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// 2. Custom Snackbar
enum AppSnackbarType { success, error, warning, info }

class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    AppSnackbarType type = AppSnackbarType.info,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    Color color;
    IconData icon;
    switch (type) {
      case AppSnackbarType.success:
        color = AppDesign.greenReceivable;
        icon = Icons.check_circle_rounded;
        break;
      case AppSnackbarType.error:
        color = AppDesign.redPayable;
        icon = Icons.error_rounded;
        break;
      case AppSnackbarType.warning:
        color = AppDesign.amberWarning;
        icon = Icons.warning_rounded;
        break;
      case AppSnackbarType.info:
      default:
        color = Colors.blue;
        icon = Icons.info_rounded;
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.fixed,
        backgroundColor: isDark ? AppDesign.darkCard : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: Border(
          top: BorderSide(color: color.withValues(alpha: 0.4), width: 1.2),
        ),
        elevation: 6,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.grey.shade900,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: color,
                onPressed: onActionPressed,
              )
            : null,
      ),
    );
  }
}

// 3. Haptic Feedback Helper
class AppHaptics {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void vibrate() => HapticFeedback.vibrate();
}

// 4. Custom Error Handling Widget
class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    this.title = 'An error occurred',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppDesign.redPayable,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              AppButton(
                label: 'Retry',
                onPressed: onRetry!,
                backgroundColor: AppDesign.primaryEmerald,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 5. Custom Premium Confirmation Dialog
class AppConfirmationDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;

  const AppConfirmationDialog({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
      titlePadding: const EdgeInsets.all(AppDesign.space20),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppDesign.space20),
      actionsPadding: const EdgeInsets.all(AppDesign.space16),
      title: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: Text(
        description,
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            cancelLabel,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: iconColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
