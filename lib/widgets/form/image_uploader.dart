import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/design_system.dart';
import '../../app/theme.dart';

class AdminImageUploader extends StatelessWidget {
  final bool uploading;
  final VoidCallback? onTap;
  final String title;
  final String subtitle;

  const AdminImageUploader({
    super.key,
    required this.uploading,
    required this.onTap,
    this.title = 'Seleccionar imagen',
    this.subtitle = 'Formatos permitidos: JPG, PNG, WEBP o GIF',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          AdminRadius.large,
        ),
        onTap: uploading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AdminColors.background,
            borderRadius: BorderRadius.circular(
              AdminRadius.large,
            ),
            border: Border.all(
              color: uploading
                  ? AdminColors.primary
                  : AdminBorders.soft,
              width: uploading ? 1.5 : 1,
            ),
          ),
          child: uploading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 38,
                      width: 38,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AdminColors.primary,
                      ),
                    ),
                    const SizedBox(height: AdminSpacing.md),
                    Text(
                      'Subiendo imagen...',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AdminColors.textDark,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 65,
                      width: 65,
                      decoration: AdminDecorations.primaryTint(
                        radius: AdminRadius.medium,
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        size: 34,
                        color: AdminColors.primary,
                      ),
                    ),
                    const SizedBox(height: AdminSpacing.md),
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AdminColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AdminSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AdminSpacing.md,
                      ),
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textSoft,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}