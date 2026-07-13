import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/design_system.dart';
import '../../app/theme.dart';

class AdminOutlinedButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;
  final Color? color;
  final Color? borderColor;
  final bool isLoading;

  const AdminOutlinedButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.expand = false,
    this.color,
    this.borderColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = color ?? AdminColors.textDark;
    final effectiveBorderColor =
        borderColor ?? foregroundColor.withOpacity(0.35);

    final button = SizedBox(
      height: AdminSizes.buttonHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          disabledForegroundColor: foregroundColor.withOpacity(0.45),
          side: BorderSide(
            color: effectiveBorderColor,
            width: 1.1,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AdminRadius.medium,
            ),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 21,
                width: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: foregroundColor,
                ),
              )
            : Row(
                mainAxisSize:
                    expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 21,
                    ),
                    const SizedBox(width: 9),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );

    if (expand) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}