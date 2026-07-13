import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/design_system.dart';
import '../../app/theme.dart';

class AdminSecondaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;

  const AdminSecondaryButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: AdminSizes.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.textDark,
          side: AdminBorders.strongSide,
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AdminRadius.medium,
            ),
          ),
        ),
        child: Row(
          mainAxisSize:
              expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 21),
              const SizedBox(width: 9),
            ],
            Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w900,
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