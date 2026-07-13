import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/design_system.dart';
import '../../app/theme.dart';

class AdminImagePreview extends StatelessWidget {
  final String imageUrl;
  final double height;

  const AdminImagePreview({
    super.key,
    required this.imageUrl,
    this.height = 280,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AdminColors.background,
          borderRadius: BorderRadius.circular(
            AdminRadius.large,
          ),
          border: Border.all(
            color: AdminBorders.soft,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_outlined,
              size: 52,
              color: AdminColors.textSoft,
            ),
            const SizedBox(height: AdminSpacing.sm),
            Text(
              'La vista previa aparecerá aquí',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AdminColors.textSoft,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        AdminRadius.large,
      ),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return Container(
            width: double.infinity,
            height: height,
            color: AdminColors.background,
            child: const Center(
              child: CircularProgressIndicator(
                color: AdminColors.primary,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) {
          return Container(
            width: double.infinity,
            height: height,
            color: AdminColors.primaryLight,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 52,
                  color: AdminColors.primary,
                ),
                SizedBox(height: AdminSpacing.sm),
                Text('No se pudo cargar la imagen'),
              ],
            ),
          );
        },
      ),
    );
  }
}