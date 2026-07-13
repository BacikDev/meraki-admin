import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/design_system.dart';
import '../app/theme.dart';
import '../controller/users_admin_controller.dart';
import '../models/admin_user_model.dart';
import '../widgets/buttons/admin_outlined_button.dart';
import '../widgets/form/admin_dropdown.dart';
import '../widgets/layout/admin_crud_screen.dart';

class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key});

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> {
  late final UsersAdminController controller;

  @override
  void initState() {
    super.initState();

    controller = Get.isRegistered<UsersAdminController>()
        ? Get.find<UsersAdminController>()
        : Get.put(UsersAdminController());
  }

  Future<void> _changeRole(
    AdminUserModel user,
    String role,
  ) async {
    if (user.role == role) return;

    await controller.updateUserRole(
      user: user,
      role: role,
    );
  }

  Future<void> _toggleStatus(
    AdminUserModel user,
  ) async {
    final newStatus = !user.isActive;

    final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: Text(
              newStatus
                  ? 'Activar usuario'
                  : 'Bloquear usuario',
            ),
            content: Text(
              newStatus
                  ? '¿Querés volver a habilitar a ${user.displayName}?'
                  : '¿Querés bloquear a ${user.displayName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                child: Text(
                  newStatus ? 'Activar' : 'Bloquear',
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await controller.updateUserStatus(
      user: user,
      isActive: newStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminCrudScreen(
      title: 'Usuarios',
      subtitle:
          'Administrá roles, estados y accesos de los usuarios registrados.',
      searchHint: 'Buscar por nombre, correo o rol...',
      showAddButton: false,
      onSearch: controller.updateSearch,
      child: Obx(() {
        // Lecturas reactivas explícitas.
        final isLoading = controller.isLoading.value;
        final isUpdating = controller.isUpdating.value;
        final selectedRole = controller.selectedRole.value;
        final selectedStatus = controller.selectedStatus.value;
        final searchQuery = controller.searchQuery.value;

        final users = controller.filteredUsers.toList();
        final allUsers = controller.users.toList();

        final hasFilters = searchQuery.isNotEmpty ||
            selectedRole != null ||
            selectedStatus != null;

        return Column(
          children: [
            _buildFilters(
              selectedRole: selectedRole,
              selectedStatus: selectedStatus,
              resultCount: users.length,
              hasFilters: hasFilters,
              enabled: !isUpdating,
            ),

            const SizedBox(height: AdminSpacing.md),

            Expanded(
              child: _buildUsersContent(
                isLoading: isLoading,
                users: users,
                allUsers: allUsers,
                hasFilters: hasFilters,
                isUpdating: isUpdating,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFilters({
    required String? selectedRole,
    required bool? selectedStatus,
    required int resultCount,
    required bool hasFilters,
    required bool enabled,
  }) {
    final roleItems = <String?>[
      null,
      ...controller.roles,
    ];

    final statusItems = <bool?>[
      null,
      true,
      false,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: AdminDecorations.card,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final roleDropdown = AdminDropdown<String?>(
            label: 'Rol',
            value: selectedRole,
            items: roleItems,
            itemLabel: (value) {
              if (value == null) {
                return 'Todos los roles';
              }

              return _roleLabel(value);
            },
            onChanged: enabled
                ? controller.updateRoleFilter
                : (_) {},
          );

          final statusDropdown = AdminDropdown<bool?>(
            label: 'Estado',
            value: selectedStatus,
            items: statusItems,
            itemLabel: (value) {
              if (value == null) {
                return 'Todos los estados';
              }

              return value ? 'Activos' : 'Bloqueados';
            },
            onChanged: enabled
                ? controller.updateStatusFilter
                : (_) {},
          );

          final footer = _UsersFilterFooter(
            count: resultCount,
            hasFilters: hasFilters,
            onClear: enabled
                ? controller.clearFilters
                : () {},
          );

          if (compact) {
            return Column(
              children: [
                roleDropdown,
                const SizedBox(height: AdminSpacing.sm),
                statusDropdown,
                const SizedBox(height: AdminSpacing.md),
                footer,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: roleDropdown),
              const SizedBox(width: AdminSpacing.sm),
              Expanded(child: statusDropdown),
              const SizedBox(width: AdminSpacing.md),
              footer,
            ],
          );
        },
      ),
    );
  }

  Widget _buildUsersContent({
    required bool isLoading,
    required List<AdminUserModel> users,
    required List<AdminUserModel> allUsers,
    required bool hasFilters,
    required bool isUpdating,
  }) {
    if (isLoading && allUsers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AdminColors.primary,
        ),
      );
    }

    if (users.isEmpty) {
      return _EmptyUsersState(
        hasFilters: hasFilters,
        onClearFilters: controller.clearFilters,
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: AdminColors.primary,
          onRefresh: controller.refreshUsers,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    bottom: AdminSpacing.md,
                  ),
                  itemCount: users.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AdminSpacing.sm),
                  itemBuilder: (context, index) {
                    final user = users[index];

                    return _UserMobileCard(
                      user: user,
                      roles: controller.roles,
                      enabled: !isUpdating,
                      onRoleChanged: (role) {
                        if (role == null) return;

                        _changeRole(user, role);
                      },
                      onToggleStatus: () {
                        _toggleStatus(user);
                      },
                    );
                  },
                );
              }

              return _UsersTable(
                users: users,
                roles: controller.roles,
                enabled: !isUpdating,
                onRoleChanged: _changeRole,
                onToggleStatus: _toggleStatus,
              );
            },
          ),
        ),

        if (isUpdating)
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.45),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AdminColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';

      case 'editor':
        return 'Editor';

      default:
        return 'Usuario';
    }
  }
}

class _UsersFilterFooter extends StatelessWidget {
  final int count;
  final bool hasFilters;
  final VoidCallback onClear;

  const _UsersFilterFooter({
    required this.count,
    required this.hasFilters,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AdminSpacing.sm,
      runSpacing: AdminSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
          decoration: AdminDecorations.primaryTint(),
          child: Text(
            '$count usuarios',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AdminColors.primary,
            ),
          ),
        ),
        if (hasFilters)
          AdminOutlinedButton(
            text: 'Limpiar',
            icon: Icons.filter_alt_off_rounded,
            onPressed: onClear,
          ),
      ],
    );
  }
}

class _UsersTable extends StatelessWidget {
  final List<AdminUserModel> users;
  final List<String> roles;
  final bool enabled;

  final Future<void> Function(
    AdminUserModel user,
    String role,
  ) onRoleChanged;

  final Future<void> Function(
    AdminUserModel user,
  ) onToggleStatus;

  const _UsersTable({
    required this.users,
    required this.roles,
    required this.enabled,
    required this.onRoleChanged,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AdminDecorations.card,
      child: Column(
        children: [
          const _UsersTableHeader(),

          const Divider(
            height: 1,
            color: AdminBorders.soft,
          ),

          Expanded(
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: AdminBorders.soft,
              ),
              itemBuilder: (context, index) {
                final user = users[index];

                return _UserTableRow(
                  user: user,
                  roles: roles,
                  enabled: enabled,
                  onRoleChanged: (role) {
                    if (role == null) return;

                    onRoleChanged(user, role);
                  },
                  onToggleStatus: () {
                    onToggleStatus(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersTableHeader extends StatelessWidget {
  const _UsersTableHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: 15,
      ),
      child: Row(
        children: [
          SizedBox(width: 54),
          SizedBox(width: AdminSpacing.md),

          Expanded(
            flex: 3,
            child: _HeaderText('Usuario'),
          ),

          Expanded(
            flex: 3,
            child: _HeaderText('Correo'),
          ),

          Expanded(
            flex: 2,
            child: _HeaderText('Rol'),
          ),

          Expanded(
            child: _HeaderText('Estado'),
          ),

          SizedBox(
            width: 150,
            child: _HeaderText('Acciones'),
          ),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;

  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 12,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w900,
        color: AdminColors.textSoft,
      ),
    );
  }
}

class _UserTableRow extends StatelessWidget {
  final AdminUserModel user;
  final List<String> roles;
  final bool enabled;
  final ValueChanged<String?> onRoleChanged;
  final VoidCallback onToggleStatus;

  const _UserTableRow({
    required this.user,
    required this.roles,
    required this.enabled,
    required this.onRoleChanged,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final safeRole = roles.contains(user.role)
        ? user.role
        : 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: 13,
      ),
      child: Row(
        children: [
          _UserAvatar(user: user),

          const SizedBox(width: AdminSpacing.md),

          Expanded(
            flex: 3,
            child: Text(
              user.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AdminColors.textDark,
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              user.email.isEmpty
                  ? 'Sin correo'
                  : user.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AdminColors.textSoft,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safeRole,
                isExpanded: true,
                items: roles
                    .map(
                      (role) => DropdownMenuItem<String>(
                        value: role,
                        child: Text(
                          _roleLabel(role),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: enabled ? onRoleChanged : null,
              ),
            ),
          ),

          Expanded(
            child: _StatusBadge(
              isActive: user.isActive,
            ),
          ),

          SizedBox(
            width: 150,
            child: Align(
              alignment: Alignment.centerRight,
              child: AdminOutlinedButton(
                text: user.isActive
                    ? 'Bloquear'
                    : 'Activar',
                icon: user.isActive
                    ? Icons.block_rounded
                    : Icons.check_circle_outline_rounded,
                color: user.isActive
                    ? Colors.redAccent
                    : Colors.green,
                onPressed: enabled
                    ? onToggleStatus
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';

      case 'editor':
        return 'Editor';

      default:
        return 'Usuario';
    }
  }
}

class _UserMobileCard extends StatelessWidget {
  final AdminUserModel user;
  final List<String> roles;
  final bool enabled;
  final ValueChanged<String?> onRoleChanged;
  final VoidCallback onToggleStatus;

  const _UserMobileCard({
    required this.user,
    required this.roles,
    required this.enabled,
    required this.onRoleChanged,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final safeRole = roles.contains(user.role)
        ? user.role
        : 'user';

    return Container(
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: AdminDecorations.card,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserAvatar(
                user: user,
                size: 58,
              ),

              const SizedBox(width: AdminSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AdminColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      user.email.isEmpty
                          ? 'Sin correo'
                          : user.email,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textSoft,
                      ),
                    ),

                    const SizedBox(height: AdminSpacing.sm),

                    _StatusBadge(
                      isActive: user.isActive,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AdminSpacing.md),

          DropdownButtonFormField<String>(
            initialValue: safeRole,
            items: roles
                .map(
                  (role) => DropdownMenuItem<String>(
                    value: role,
                    child: Text(
                      _roleLabel(role),
                    ),
                  ),
                )
                .toList(),
            onChanged: enabled ? onRoleChanged : null,
            decoration: InputDecoration(
              labelText: 'Rol',
              filled: true,
              fillColor: AdminColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AdminRadius.medium,
                ),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: AdminSpacing.md),

          AdminOutlinedButton(
            text: user.isActive
                ? 'Bloquear usuario'
                : 'Activar usuario',
            icon: user.isActive
                ? Icons.block_rounded
                : Icons.check_circle_outline_rounded,
            expand: true,
            color: user.isActive
                ? Colors.redAccent
                : Colors.green,
            onPressed: enabled
                ? onToggleStatus
                : null,
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';

      case 'editor':
        return 'Editor';

      default:
        return 'Usuario';
    }
  }
}

class _UserAvatar extends StatelessWidget {
  final AdminUserModel user;
  final double size;

  const _UserAvatar({
    required this.user,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    final initial = user.displayName.trim().isEmpty
        ? 'U'
        : user.displayName
            .trim()
            .substring(0, 1)
            .toUpperCase();

    if (user.avatarUrl.trim().isEmpty) {
      return _buildFallback(initial);
    }

    return ClipOval(
      child: Image.network(
        user.avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _buildFallback(initial);
        },
      ),
    );
  }

  Widget _buildFallback(String initial) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AdminColors.primaryLight,
      child: Text(
        initial,
        style: GoogleFonts.nunito(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w900,
          color: AdminColors.primary,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? Colors.green
        : Colors.redAccent;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            AdminRadius.small,
          ),
        ),
        child: Text(
          isActive ? 'Activo' : 'Bloqueado',
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _EmptyUsersState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _EmptyUsersState({
    required this.hasFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 70),

        Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),
            padding: const EdgeInsets.all(
              AdminSpacing.xl,
            ),
            decoration: AdminDecorations.card,
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: AdminDecorations.primaryTint(
                    radius: AdminRadius.large,
                  ),
                  child: Icon(
                    hasFilters
                        ? Icons.filter_alt_off_rounded
                        : Icons.people_alt_outlined,
                    size: 40,
                    color: AdminColors.primary,
                  ),
                ),

                const SizedBox(height: AdminSpacing.md),

                Text(
                  hasFilters
                      ? 'No hay usuarios coincidentes'
                      : 'Todavía no hay usuarios',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AdminColors.textDark,
                  ),
                ),

                const SizedBox(height: AdminSpacing.sm),

                Text(
                  hasFilters
                      ? 'Probá modificar o limpiar los filtros.'
                      : 'Los perfiles registrados aparecerán aquí.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textSoft,
                  ),
                ),

                if (hasFilters) ...[
                  const SizedBox(height: AdminSpacing.lg),

                  AdminOutlinedButton(
                    text: 'Limpiar filtros',
                    icon: Icons.filter_alt_off_rounded,
                    onPressed: onClearFilters,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}