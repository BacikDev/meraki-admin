import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/auth_admin_controller.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/login_admin_screen.dart';
import 'theme.dart';

class MerakiAdminApp extends StatelessWidget {
  const MerakiAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(AuthAdminController());

    return GetMaterialApp(
      title: 'Meraki Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.lightTheme,
      home: Obx(() {
        if (authController.isLoggedIn.value && authController.isAdmin.value) {
          return const AdminDashboardScreen();
        }

        return const LoginAdminScreen();
      }),
    );
  }
}