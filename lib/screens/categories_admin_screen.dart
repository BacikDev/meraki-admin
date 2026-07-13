import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/design_system.dart';
import '../app/theme.dart';
import '../controller/dashboard_controller.dart';
import '../controller/categories_admin_controller.dart';
import '../models/admin_category_model.dart';
import '../widgets/buttons/admin_outlined_button.dart';
import '../widgets/dialogs/admin_delete_dialog.dart';
import '../widgets/layout/admin_crud_screen.dart';
import 'category_form_screen.dart';

class CategoriesAdminScreen extends StatefulWidget {
  const CategoriesAdminScreen({super.key});

  @override
  State<CategoriesAdminScreen> createState() =>
      _CategoriesAdminScreenState();
}

class _CategoriesAdminScreenState extends State<CategoriesAdminScreen> {
  final CategoriesAdminController controller =
      Get.put(CategoriesAdminController());

  DashboardController get dashboardController =>
    Get.find<DashboardController>();

Future<void> _refreshDashboard() async {
  if (Get.isRegistered<DashboardController>()) {
    await dashboardController.refreshDashboard();
  }
}

  Future<void> _openCreateCategory() async {
    final result = await Get.to(
      () => const CategoryFormScreen(),
    );

    if (result == true) {
  await controller.loadCategories();
  await _refreshDashboard();
}
    
  }

  Future<void> _openEditCategory(
    AdminCategoryModel category,
  ) async {
    final result = await Get.to(
      () => CategoryFormScreen(
        category: category,
      ),
    );

    if (result == true) {
  await controller.loadCategories();
  await _refreshDashboard();
}
  }

  Future<void> _deleteCategory(
    AdminCategoryModel category,
  ) async {
    final confirmed = await showAdminDeleteDialog(
      title: 'Eliminar categoría',
      message:
          '¿Seguro que querés eliminar "${category.nombre}"? Esta acción no se puede deshacer.',
    );

    if (!confirmed) return;

final success =
    await controller.deleteCategory(category.id);

if (success) {
  await _refreshDashboard();
}  }

  @override
  Widget build(BuildContext context) {
    return AdminCrudScreen(
      title: 'Categorías',
      subtitle:
          'Organizá las categorías disponibles en la aplicación.',
      searchHint: 'Buscar por nombre o descripción...',
      addButtonText: 'Nueva categoría',
      onSearch: controller.searchCategories,
      onAdd: _openCreateCategory,
      child: Obx(() {
        if (controller.isLoading.value &&
            controller.categories.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AdminColors.primary,
            ),
          );
        }

        final categories = controller.filteredCategories;

        if (categories.isEmpty) {
          return _EmptyCategoriesState(
            hasSearch: controller.searchQuery.value.isNotEmpty,
            onCreate: _openCreateCategory,
          );
        }

        return RefreshIndicator(
          color: AdminColors.primary,
          onRefresh: controller.refreshCategories,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 720) {
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AdminSpacing.sm),
                  itemBuilder: (context, index) {
                    final category = categories[index];

                    return _CategoryMobileCard(
                      category: category,
                      onEdit: () => _openEditCategory(category),
                      onDelete: () => _deleteCategory(category),
                    );
                  },
                );
              }

              return _CategoriesTable(
                categories: categories,
                onEdit: _openEditCategory,
                onDelete: _deleteCategory,
              );
            },
          ),
        );
      }),
    );
  }
}

class _CategoriesTable extends StatelessWidget {
  final List<AdminCategoryModel> categories;
  final ValueChanged<AdminCategoryModel> onEdit;
  final ValueChanged<AdminCategoryModel> onDelete;

  const _CategoriesTable({
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AdminDecorations.card,
      child: Column(
        children: [
          const _TableHeader(),
          const Divider(
            height: 1,
            color: AdminBorders.soft,
          ),
          Expanded(
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: AdminBorders.soft,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];

                return _CategoryTableRow(
                  category: category,
                  onEdit: () => onEdit(category),
                  onDelete: () => onDelete(category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: 15,
      ),
      child: Row(
        children: [
          const SizedBox(width: 68),
          const SizedBox(width: AdminSpacing.md),
          Expanded(
            flex: 3,
            child: _HeaderText('Categoría'),
          ),
          Expanded(
            flex: 4,
            child: _HeaderText('Descripción'),
          ),
          SizedBox(
            width: 190,
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

class _CategoryTableRow extends StatelessWidget {
  final AdminCategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTableRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: 14,
      ),
      child: Row(
        children: [
          _CategoryImage(
            imageUrl: category.imagen,
            size: 68,
          ),
          const SizedBox(width: AdminSpacing.md),
          Expanded(
            flex: 3,
            child: Text(
              category.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AdminColors.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              _description(category),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AdminColors.textSoft,
              ),
            ),
          ),
          SizedBox(
            width: 190,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AdminOutlinedButton(
                  text: 'Editar',
                  icon: Icons.edit_rounded,
                  onPressed: onEdit,
                ),
                const SizedBox(width: AdminSpacing.sm),
                IconButton(
                  tooltip: 'Eliminar categoría',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryMobileCard extends StatelessWidget {
  final AdminCategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryMobileCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: AdminDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryImage(
                imageUrl: category.imagen,
                size: 82,
              ),
              const SizedBox(width: AdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.nombre,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AdminColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AdminSpacing.xs),
                    Text(
                      _description(category),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.md),
          Row(
            children: [
              Expanded(
                child: AdminOutlinedButton(
                  text: 'Editar',
                  icon: Icons.edit_rounded,
                  expand: true,
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(width: AdminSpacing.sm),
              IconButton(
                tooltip: 'Eliminar categoría',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _CategoryImage({
    required this.imageUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AdminColors.primaryLight,
          borderRadius: BorderRadius.circular(
            AdminRadius.medium,
          ),
        ),
        child: const Icon(
          Icons.category_outlined,
          color: AdminColors.primary,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        AdminRadius.medium,
      ),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: size,
            height: size,
            color: AdminColors.primaryLight,
            child: const Icon(
              Icons.broken_image_outlined,
              color: AdminColors.primary,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyCategoriesState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onCreate;

  const _EmptyCategoriesState({
    required this.hasSearch,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 70),
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(AdminSpacing.xl),
            decoration: AdminDecorations.card,
            child: Column(
              children: [
                Container(
                  height: 76,
                  width: 76,
                  decoration: AdminDecorations.primaryTint(
                    radius: AdminRadius.large,
                  ),
                  child: Icon(
                    hasSearch
                        ? Icons.search_off_rounded
                        : Icons.category_outlined,
                    size: 40,
                    color: AdminColors.primary,
                  ),
                ),
                const SizedBox(height: AdminSpacing.md),
                Text(
                  hasSearch
                      ? 'No encontramos categorías'
                      : 'Todavía no hay categorías',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AdminColors.textDark,
                  ),
                ),
                const SizedBox(height: AdminSpacing.sm),
                Text(
                  hasSearch
                      ? 'Probá con otro nombre o descripción.'
                      : 'Creá la primera categoría para organizar los patrones.',
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
        ),
      ],
    );
  }
}

String _description(AdminCategoryModel category) {
  final value = category.descripcion?.trim() ?? '';

  return value.isEmpty ? 'Sin descripción' : value;
}