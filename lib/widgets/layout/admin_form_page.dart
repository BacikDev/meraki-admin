import 'package:flutter/material.dart';

import '../../app/design_system.dart';
import '../../app/theme.dart';

class AdminFormPage extends StatelessWidget {
  final Widget child;

  const AdminFormPage({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                compact
                    ? AdminSpacing.md
                    : AdminSpacing.lg,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 980,
                  ),
                  width: double.infinity,
                  padding: EdgeInsets.all(
                    compact
                        ? AdminSpacing.md
                        : AdminSpacing.lg,
                  ),
                  decoration: AdminDecorations.card,
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}