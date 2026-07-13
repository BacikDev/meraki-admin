import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../controller/auth_admin_controller.dart';

class AdminLayoutItem {
  final String title;
  final IconData icon;
  final Widget page;

  const AdminLayoutItem({
    required this.title,
    required this.icon,
    required this.page,
  });
}

class AdminLayout extends StatefulWidget {
  final List<AdminLayoutItem> items;
  final int initialIndex;

  const AdminLayout({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  late int selectedIndex;

  @override
  void initState() {
    super.initState();

    selectedIndex = widget.initialIndex.clamp(
      0,
      widget.items.length - 1,
    );
  }

  void _changePage(int index) {
    setState(() {
      selectedIndex = index;
    });

    if (scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No hay módulos configurados'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 950;

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: AdminColors.background,
          drawer: isCompact
              ? Drawer(
                  width: 285,
                  backgroundColor: AdminColors.white,
                  child: SafeArea(
                    child: _AdminSidebar(
                      items: widget.items,
                      selectedIndex: selectedIndex,
                      onChanged: _changePage,
                    ),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!isCompact)
                _AdminSidebar(
                  items: widget.items,
                  selectedIndex: selectedIndex,
                  onChanged: _changePage,
                ),
              Expanded(
                child: Column(
                  children: [
                    _AdminTopBar(
                      title: widget.items[selectedIndex].title,
                      showMenuButton: isCompact,
                      onMenuTap: () {
                        scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: selectedIndex,
                        children: widget.items
                            .map((item) => item.page)
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final List<AdminLayoutItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _AdminSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthAdminController>();

    return Container(
      width: 290,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AdminColors.white,
        border: Border(
          right: BorderSide(
            color: Color(0xFFEDE4EA),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
              child: _BrandHeader(
                email: authController.currentUser?.email,
              ),
            ),
            const Divider(
              height: 1,
              color: Color(0xFFF0E7EC),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                children: [
                  const _MenuSectionTitle(title: 'NAVEGACIÓN'),
                  ...List.generate(
                    items.length,
                    (index) {
                      final item = items[index];

                      return _MenuItem(
                        icon: item.icon,
                        title: item.title,
                        selected: selectedIndex == index,
                        onTap: () => onChanged(index),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              color: Color(0xFFF0E7EC),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _LogoutButton(
                onTap: authController.signOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  final String title;
  final bool showMenuButton;
  final VoidCallback onMenuTap;

  const _AdminTopBar({
    required this.title,
    required this.showMenuButton,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthAdminController>();
    final email = authController.currentUser?.email ?? 'Administrador';

    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AdminColors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEDE4EA),
          ),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            IconButton(
              tooltip: 'Abrir menú',
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu_rounded),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AdminColors.textDark,
              ),
            ),
          ),
          if (MediaQuery.of(context).size.width >= 720)
            Container(
              width: 260,
              height: 44,
              decoration: BoxDecoration(
                color: AdminColors.background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 21,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AdminColors.textDark,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: email,
            child: CircleAvatar(
              radius: 21,
              backgroundColor: AdminColors.primaryLight,
              child: Text(
                email.isEmpty ? 'A' : email.substring(0, 1).toUpperCase(),
                style: GoogleFonts.nunito(
                  color: AdminColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final String? email;

  const _BrandHeader({
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: AdminColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.local_florist_rounded,
            color: AdminColors.primary,
            size: 29,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meraki',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: AdminColors.textDark,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'ADMIN PANEL',
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w900,
                  color: AdminColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuSectionTitle extends StatelessWidget {
  final String title;

  const _MenuSectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 9),
      child: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 10,
          letterSpacing: 1.7,
          fontWeight: FontWeight.w900,
          color: AdminColors.textSoft.withOpacity(0.75),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AdminColors.primaryLight
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 23,
                  color: selected
                      ? AdminColors.primary
                      : AdminColors.textSoft,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: selected
                          ? AdminColors.primary
                          : AdminColors.textDark,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    height: 7,
                    width: 7,
                    decoration: const BoxDecoration(
                      color: AdminColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Cerrar sesión'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        foregroundColor: AdminColors.textDark,
        side: const BorderSide(
          color: Color(0xFFE8DCE3),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        textStyle: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}