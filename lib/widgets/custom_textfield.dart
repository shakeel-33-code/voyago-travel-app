import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';

class CustomTextField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final void Function(String)? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double borderRadius;
  final bool autofocus;

  const CustomTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.inputFormatters,
    this.focusNode,
    this.contentPadding,
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.borderRadius = AppTheme.borderRadius12,
    this.autofocus = false,
  });

  // Email input constructor
  const CustomTextField.email({
    super.key,
    this.labelText = 'Email',
    this.hintText = 'Enter your email',
    this.helperText,
    this.errorText,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
  })  : keyboardType = TextInputType.emailAddress,
        textInputAction = TextInputAction.next,
        obscureText = false,
        readOnly = false,
        maxLines = 1,
        minLines = null,
        maxLength = null,
        onTap = null,
        prefixIcon = const Icon(Icons.email_outlined),
        suffixIcon = null,
        prefixText = null,
        suffixText = null,
        inputFormatters = null,
        contentPadding = null,
        textStyle = null,
        labelStyle = null,
        hintStyle = null,
        fillColor = null,
        borderColor = null,
        focusedBorderColor = null,
        borderRadius = AppTheme.borderRadius12;

  // Password input constructor
  const CustomTextField.password({
    super.key,
    this.labelText = 'Password',
    this.hintText = 'Enter your password',
    this.helperText,
    this.errorText,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
  })  : keyboardType = TextInputType.visiblePassword,
        textInputAction = TextInputAction.done,
        obscureText = true,
        readOnly = false,
        maxLines = 1,
        minLines = null,
        maxLength = null,
        onTap = null,
        prefixIcon = const Icon(Icons.lock_outlined),
        suffixIcon = null, // Will be handled in the widget
        prefixText = null,
        suffixText = null,
        inputFormatters = null,
        contentPadding = null,
        textStyle = null,
        labelStyle = null,
        hintStyle = null,
        fillColor = null,
        borderColor = null,
        focusedBorderColor = null,
        borderRadius = AppTheme.borderRadius12;

  // Search input constructor
  const CustomTextField.search({
    super.key,
    this.labelText,
    this.hintText = 'Search...',
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
  })  : keyboardType = TextInputType.text,
        textInputAction = TextInputAction.search,
        obscureText = false,
        readOnly = false,
        maxLines = 1,
        minLines = null,
        maxLength = null,
        validator = null,
        onTap = null,
        prefixIcon = const Icon(Icons.search),
        suffixIcon = null,
        prefixText = null,
        suffixText = null,
        inputFormatters = null,
        contentPadding = null,
        textStyle = null,
        labelStyle = null,
        hintStyle = null,
        fillColor = null,
        borderColor = null,
        focusedBorderColor = null,
        borderRadius = AppTheme.borderRadius12;

  // Multiline text area constructor
  const CustomTextField.multiline({
    super.key,
    this.labelText,
    this.hintText = 'Enter text...',
    this.helperText,
    this.errorText,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.minLines = 3,
    this.maxLines = 5,
    this.maxLength,
    this.autofocus = false,
  })  : keyboardType = TextInputType.multiline,
        textInputAction = TextInputAction.newline,
        obscureText = false,
        readOnly = false,
        onTap = null,
        prefixIcon = null,
        suffixIcon = null,
        prefixText = null,
        suffixText = null,
        inputFormatters = null,
        contentPadding = null,
        textStyle = null,
        labelStyle = null,
        hintStyle = null,
        fillColor = null,
        borderColor = null,
        focusedBorderColor = null,
        borderRadius = AppTheme.borderRadius12;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isPasswordVisible = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: widget.labelStyle ??
                Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
          ),
          const SizedBox(height: AppTheme.spacing8),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.obscureText && !_isPasswordVisible,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          onFieldSubmitted: widget.onSubmitted,
          inputFormatters: widget.inputFormatters,
          autofocus: widget.autofocus,
          style: widget.textStyle ??
              Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: _buildSuffixIcon(),
            prefixText: widget.prefixText,
            suffixText: widget.suffixText,
            filled: true,
            fillColor: widget.fillColor ?? AppTheme.surfaceColor,
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing16,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: widget.borderColor ?? Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: widget.borderColor ?? Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: widget.focusedBorderColor ?? AppTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
            hintStyle: widget.hintStyle ??
                Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
            helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            errorStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.errorColor,
                ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          color: AppTheme.textSecondary,
        ),
        onPressed: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
      );
    }
    return widget.suffixIcon;
  }
}

// Specialized input formatters
class CustomInputFormatters {
  static List<TextInputFormatter> phoneNumber = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ];

  static List<TextInputFormatter> price = [
    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
  ];

  static List<TextInputFormatter> alphabetOnly = [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
  ];

  static List<TextInputFormatter> alphanumeric = [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
  ];
}

// Custom validators
class CustomValidators {
  static String? Function(String?) email = (String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  };

  static String? Function(String?) password = (String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  };

  static String? Function(String?) required = (String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  };

  static String? Function(String?) phoneNumber = (String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  };
}