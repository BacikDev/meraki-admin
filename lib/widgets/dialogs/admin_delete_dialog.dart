import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/design_system.dart';
import '../../app/theme.dart';
import '../buttons/admin_primary_button.dart';
import '../buttons/admin_secondary_button.dart';

Future<bool> showAdminDeleteDialog({
  required String title,
  required String message,
}) async {
  final result = await Get.dialog<bool>(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(AdminSpacing.lg),
        decoration: AdminDecorations.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 62,
              width: 62,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 32,
              ),
            ),
            const SizedBox(height: AdminSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: AdminColors.textDark,
              ),
            ),
            const SizedBox(height: AdminSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: AdminColors.textSoft,
              ),
            ),
            const SizedBox(height: AdminSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AdminSecondaryButton(
                    text: 'Cancelar',
                    expand: true,
                    onPressed: () => Get.back(result: false),
                  ),
                ),
                const SizedBox(width: AdminSpacing.sm),
                Expanded(
                  child: AdminPrimaryButton(
                    text: 'Eliminar',
                    icon: Icons.delete_outline_rounded,
                    expand: true,
                    onPressed: () => Get.back(result: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: false,
  );

  return result ?? false;
}