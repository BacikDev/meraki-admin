import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../controller/dashboard_controller.dart';
import '../layout/admin_layout.dart';
import 'categories_admin_screen.dart';
import 'dashboard_home.dart';
import 'patterns_admin_screen.dart';
import 'analytics_screen.dart';
import 'users_admin_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.put(DashboardController());

    return AdminLayout(
      items: [
        AdminLayoutItem(
          title: 'Dashboard',
          icon: Icons.dashboard_rounded,
          page: DashboardHome(
            controller: dashboardController,
          ),
        ),
        const AdminLayoutItem(
          title: 'Patrones',
          icon: Icons.spa_rounded,
          page: PatternsAdminScreen(),
        ),
        const AdminLayoutItem(
          title: 'Categorías',
          icon: Icons.category_rounded,
          page: CategoriesAdminScreen(),
        ),
        const AdminLayoutItem(
          title: 'Usuarios',
          icon: Icons.people_alt_outlined,
          page: UsersAdminScreen(),
        ),
        const AdminLayoutItem(
          title: 'Favoritos',
          icon: Icons.favorite_border_rounded,
          page: _ComingSoonPage(
            title: 'Favoritos',
            icon: Icons.favorite_border_rounded,
          ),
        ),
        const AdminLayoutItem(
          title: 'Analytics',
          icon: Icons.analytics_outlined,
          page: AnalyticsScreen(),
        ),
        const AdminLayoutItem(
          title: 'Storage',
          icon: Icons.cloud_outlined,
          page: _ComingSoonPage(
            title: 'Storage',
            icon: Icons.cloud_outlined,
          ),
        ),
        const AdminLayoutItem(
          title: 'IA',
          icon: Icons.auto_awesome_rounded,
          page: _ComingSoonPage(
            title: 'Inteligencia artificial',
            icon: Icons.auto_awesome_rounded,
          ),
        ),
        const AdminLayoutItem(
          title: 'Ajustes',
          icon: Icons.settings_outlined,
          page: _ComingSoonPage(
            title: 'Ajustes',
            icon: Icons.settings_outlined,
          ),
        ),
      ],
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ComingSoonPage({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AdminColors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 60,
              color: AdminColors.primary,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AdminColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Este módulo estará disponible próximamente.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AdminColors.textSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}