import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/design_system.dart';
import '../../app/theme.dart';

class AdminSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const AdminSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        bottom: AdminSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AdminBorders.soft,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AdminColors.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AdminColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}