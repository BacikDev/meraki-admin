import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/design_system.dart';
import '../../app/theme.dart';

class AdminFormHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  const AdminFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: 'Volver',
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ),
        ),
        const SizedBox(width: AdminSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AdminColors.textDark,
                ),
              ),
              const SizedBox(height: AdminSpacing.xs),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}