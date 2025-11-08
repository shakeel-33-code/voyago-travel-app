import 'package:flutter/material.dart';
import '../utils/theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  final bool isLoading;
  final bool isExpanded;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.borderRadius,
  });

  // Primary button constructor
  const CustomButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.padding,
    this.borderRadius,
  })  : style = null,
        backgroundColor = AppTheme.primaryColor,
        textColor = Colors.white;

  // Secondary button constructor
  const CustomButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.padding,
    this.borderRadius,
  })  : style = null,
        backgroundColor = AppTheme.secondaryColor,
        textColor = Colors.white;

  // Outline button constructor
  const CustomButton.outline({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.padding,
    this.borderRadius,
  })  : style = null,
        backgroundColor = Colors.transparent,
        textColor = AppTheme.primaryColor;

  // Text button constructor
  const CustomButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.padding,
    this.borderRadius,
  })  : style = null,
        backgroundColor = Colors.transparent,
        textColor = AppTheme.primaryColor;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = style ??
        ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.primaryColor,
          foregroundColor: textColor ?? Colors.white,
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing24,
                vertical: AppTheme.spacing16,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.borderRadius12),
            side: backgroundColor == Colors.transparent
                ? BorderSide(color: textColor ?? AppTheme.primaryColor)
                : BorderSide.none,
          ),
          elevation: backgroundColor == Colors.transparent ? 0 : 2,
          shadowColor: backgroundColor == Colors.transparent
              ? Colors.transparent
              : (backgroundColor ?? AppTheme.primaryColor).withOpacity(0.3),
        );

    Widget buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: AppTheme.spacing8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? Colors.white,
                ),
              ),
            ],
          );

    Widget button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: buttonChild,
    );

    return isExpanded
        ? SizedBox(
            width: double.infinity,
            child: button,
          )
        : button;
  }
}

// Gradient Button Widget
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final Widget? icon;
  final bool isLoading;
  final bool isExpanded;
  final Color textColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient = AppTheme.primaryGradient,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.textColor = Colors.white,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: AppTheme.spacing8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          );

    Widget button = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.borderRadius12),
        boxShadow: AppTheme.buttonShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.borderRadius12),
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing24,
                  vertical: AppTheme.spacing16,
                ),
            child: buttonChild,
          ),
        ),
      ),
    );

    return isExpanded
        ? SizedBox(
            width: double.infinity,
            child: button,
          )
        : button;
  }
}

// Icon Button with Background
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final EdgeInsetsGeometry? padding;
  final String? tooltip;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 24,
    this.padding,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppTheme.primaryColor,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppTheme.spacing12),
          child: Icon(
            icon,
            size: size,
            color: iconColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}