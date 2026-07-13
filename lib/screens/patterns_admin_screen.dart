import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/design_system.dart';
import '../app/theme.dart';
import '../controller/dashboard_controller.dart';
import '../controller/patterns_admin_controller.dart';
import '../models/admin_pattern_model.dart';
import '../widgets/buttons/admin_outlined_button.dart';
import '../widgets/buttons/admin_primary_button.dart';
import '../widgets/dialogs/admin_delete_dialog.dart';
import '../widgets/form/admin_dropdown.dart';
import '../widgets/layout/admin_crud_screen.dart';
import 'pattern_form_screen.dart';

class PatternsAdminScreen extends StatefulWidget {
  const PatternsAdminScreen({super.key});

  @override
  State<PatternsAdminScreen> createState() =>
      _PatternsAdminScreenState();
}

class _PatternsAdminScreenState extends State<PatternsAdminScreen> {
  final PatternsAdminController controller =
      Get.isRegistered<PatternsAdminController>()
          ? Get.find<PatternsAdminController>()
          : Get.put(PatternsAdminController());

  Future<void> _openCreatePattern() async {
    final result = await Get.to<bool>(
      () => const PatternFormScreen(),
    );

    if (result == true) {
      await controller.refreshPatterns();
    }
  }

  Future<void> _refreshDashboard() async {
  if (Get.isRegistered<DashboardController>()) {
    await Get.find<DashboardController>().refreshDashboard();
  }
}

  Future<void> _openEditPattern(
  AdminPatternModel pattern,
) async {
  final result = await Get.to<bool>(
    () => PatternFormScreen(
      pattern: pattern,
    ),
  );

  if (result == true) {
    await controller.refreshPatterns();
    await _refreshDashboard();
  }
}
  Future<void> _deletePattern(
    AdminPatternModel pattern,
  ) async {
    final confirmed = await showAdminDeleteDialog(
      title: 'Eliminar patrón',
      message:
          '¿Seguro que querés eliminar "${pattern.titulo}"? Esta acción no se puede deshacer.',
    );

    if (!confirmed) return;

  await controller.deletePattern(pattern);
  }

  Future<void> _duplicatePattern(
    AdminPatternModel pattern,
  ) async {
    final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Duplicar patrón'),
            content: Text(
              'Se creará una copia de "${pattern.titulo}".',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Duplicar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await controller.duplicatePattern(pattern);
  }

  @override
  Widget build(BuildContext context) {
    return AdminCrudScreen(
      title: 'Patrones',
      subtitle:
          'Administrá, filtrá y organizá los patrones publicados en Meraki.',
      searchHint: 'Buscar por título, categoría, nivel o fuente...',
      addButtonText: 'Nuevo patrón',
      onSearch: controller.updateSearch,
      onAdd: _openCreatePattern,
      child: Column(
        children: [
          _buildFilters(),
          const SizedBox(height: AdminSpacing.md),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.patterns.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AdminColors.primary,
                  ),
                );
              }

              final patterns = controller.filteredPatterns;

              if (patterns.isEmpty) {
                return _EmptyPatternsState(
                  hasFilters: controller.hasActiveFilters,
                  onCreate: _openCreatePattern,
                  onClearFilters: controller.clearFilters,
                );
              }

              return RefreshIndicator(
                color: AdminColors.primary,
                onRefresh: controller.refreshPatterns,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 850) {
                      return ListView.separated(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        itemCount: patterns.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(
                          height: AdminSpacing.sm,
                        ),
                        itemBuilder: (context, index) {
                          final pattern = patterns[index];

                          return _PatternMobileCard(
                            pattern: pattern,
                            onEdit: () =>
                                _openEditPattern(pattern),
                            onDuplicate: () =>
                                _duplicatePattern(pattern),
                            onDelete: () =>
                                _deletePattern(pattern),
                          );
                        },
                      );
                    }

                    return _PatternsTable(
                      patterns: patterns,
                      onEdit: _openEditPattern,
                      onDuplicate: _duplicatePattern,
                      onDelete: _deletePattern,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Obx(() {
      final categoryItems = <int?>[
        null,
        ...controller.categories.map<int?>(
          (item) => item['id'] as int,
        ),
      ];

      final levelItems = <String?>[
        null,
        ...controller.levels,
      ];

      final sourceItems = <String?>[
        null,
        ...controller.sources,
      ];

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AdminSpacing.md),
        decoration: AdminDecorations.card,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1050;

            final categoryDropdown = AdminDropdown<int?>(
              label: 'Categoría',
              value: controller.selectedCategoryId.value,
              items: categoryItems,
              itemLabel: (value) {
                if (value == null) {
                  return 'Todas las categorías';
                }

                return controller.categoryNameById(value);
              },
              onChanged: controller.updateCategory,
            );

            final levelDropdown = AdminDropdown<String?>(
              label: 'Nivel',
              value: controller.selectedLevel.value,
              items: levelItems,
              itemLabel: (value) {
                return value ?? 'Todos los niveles';
              },
              onChanged: controller.updateLevel,
            );

            final sourceDropdown = AdminDropdown<String?>(
              label: 'Fuente',
              value: controller.selectedSource.value,
              items: sourceItems,
              itemLabel: (value) {
                if (value == null) {
                  return 'Todas las fuentes';
                }

                return _sourceLabel(value);
              },
              onChanged: controller.updateSource,
            );

            final sortDropdown = AdminDropdown<String>(
              label: 'Ordenar',
              value: controller.sortOption.value,
              items: controller.sortOptions,
              itemLabel: (value) => value,
              onChanged: (value) {
                if (value == null) return;
                controller.updateSort(value);
              },
            );

            if (compact) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: categoryDropdown),
                      const SizedBox(width: AdminSpacing.sm),
                      Expanded(child: levelDropdown),
                    ],
                  ),
                  const SizedBox(height: AdminSpacing.sm),
                  Row(
                    children: [
                      Expanded(child: sourceDropdown),
                      const SizedBox(width: AdminSpacing.sm),
                      Expanded(child: sortDropdown),
                    ],
                  ),
                  const SizedBox(height: AdminSpacing.md),
                  _FilterFooter(
                    count: controller.totalResults,
                    hasActiveFilters:
                        controller.hasActiveFilters,
                    onClear: controller.clearFilters,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: categoryDropdown),
                const SizedBox(width: AdminSpacing.sm),
                Expanded(child: levelDropdown),
                const SizedBox(width: AdminSpacing.sm),
                Expanded(child: sourceDropdown),
                const SizedBox(width: AdminSpacing.sm),
                Expanded(child: sortDropdown),
                const SizedBox(width: AdminSpacing.md),
                _FilterFooter(
                  count: controller.totalResults,
                  hasActiveFilters:
                      controller.hasActiveFilters,
                  onClear: controller.clearFilters,
                ),
              ],
            );
          },
        ),
      );
    });
  }

  String _sourceLabel(String source) {
    switch (source.toLowerCase()) {
      case 'youtube':
        return 'YouTube';
      case 'instagram':
        return 'Instagram';
      case 'tiktok':
        return 'TikTok';
      default:
        return source;
    }
  }
}

class _FilterFooter extends StatelessWidget {
  final int count;
  final bool hasActiveFilters;
  final VoidCallback onClear;

  const _FilterFooter({
    required this.count,
    required this.hasActiveFilters,
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
            '$count resultados',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AdminColors.primary,
            ),
          ),
        ),
        if (hasActiveFilters)
          AdminOutlinedButton(
            text: 'Limpiar',
            icon: Icons.filter_alt_off_rounded,
            onPressed: onClear,
          ),
      ],
    );
  }
}

class _PatternsTable extends StatelessWidget {
  final List<AdminPatternModel> patterns;
  final ValueChanged<AdminPatternModel> onEdit;
  final ValueChanged<AdminPatternModel> onDuplicate;
  final ValueChanged<AdminPatternModel> onDelete;

  const _PatternsTable({
    required this.patterns,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AdminDecorations.card,
      child: Column(
        children: [
          const _PatternTableHeader(),
          const Divider(
            height: 1,
            color: AdminBorders.soft,
          ),
          Expanded(
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: patterns.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: AdminBorders.soft,
              ),
              itemBuilder: (context, index) {
                final pattern = patterns[index];

                return _PatternTableRow(
                  pattern: pattern,
                  onEdit: () => onEdit(pattern),
                  onDuplicate: () => onDuplicate(pattern),
                  onDelete: () => onDelete(pattern),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternTableHeader extends StatelessWidget {
  const _PatternTableHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: 15,
      ),
      child: Row(
        children: const [
          SizedBox(width: 70),
          SizedBox(width: AdminSpacing.md),
          Expanded(
            flex: 3,
            child: _HeaderText('Patrón'),
          ),
          Expanded(
            flex: 2,
            child: _HeaderText('Categoría'),
          ),
          Expanded(
            child: _HeaderText('Nivel'),
          ),
          Expanded(
            child: _HeaderText('Fuente'),
          ),
          SizedBox(
            width: 210,
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

class _PatternTableRow extends StatelessWidget {
  final AdminPatternModel pattern;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _PatternTableRow({
    required this.pattern,
    required this.onEdit,
    required this.onDuplicate,
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
          _PatternImage(
            imageUrl: pattern.imagen,
            size: 70,
          ),
          const SizedBox(width: AdminSpacing.md),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pattern.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AdminColors.textDark,
                  ),
                ),
                if (pattern.descripcion.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    pattern.descripcion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              pattern.categoriaNombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: _PatternChip(
              text: pattern.nivel,
            ),
          ),
          Expanded(
            child: _PatternChip(
              text: pattern.fuente,
            ),
          ),
          SizedBox(
            width: 210,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Duplicar patrón',
                  onPressed: onDuplicate,
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: AdminColors.textSoft,
                  ),
                ),
                IconButton(
                  tooltip: 'Editar patrón',
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: AdminColors.primary,
                  ),
                ),
                IconButton(
                  tooltip: 'Eliminar patrón',
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

class _PatternMobileCard extends StatelessWidget {
  final AdminPatternModel pattern;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _PatternMobileCard({
    required this.pattern,
    required this.onEdit,
    required this.onDuplicate,
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
              _PatternImage(
                imageUrl: pattern.imagen,
                size: 88,
              ),
              const SizedBox(width: AdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AdminColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AdminSpacing.xs),
                    Text(
                      pattern.categoriaNombre,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textSoft,
                      ),
                    ),
                    const SizedBox(height: AdminSpacing.sm),
                    Wrap(
                      spacing: AdminSpacing.xs,
                      runSpacing: AdminSpacing.xs,
                      children: [
                        _PatternChip(text: pattern.nivel),
                        _PatternChip(text: pattern.fuente),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pattern.descripcion.trim().isNotEmpty) ...[
            const SizedBox(height: AdminSpacing.md),
            Text(
              pattern.descripcion,
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
          const SizedBox(height: AdminSpacing.md),
          Row(
            children: [
              Expanded(
                child: AdminOutlinedButton(
                  text: 'Duplicar',
                  icon: Icons.copy_rounded,
                  expand: true,
                  onPressed: onDuplicate,
                ),
              ),
              const SizedBox(width: AdminSpacing.sm),
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
                tooltip: 'Eliminar patrón',
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

class _PatternImage extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _PatternImage({
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
          Icons.image_outlined,
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

class _PatternChip extends StatelessWidget {
  final String text;

  const _PatternChip({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: AdminDecorations.primaryTint(
        radius: AdminRadius.small,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AdminColors.textDark,
        ),
      ),
    );
  }
}

class _EmptyPatternsState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onCreate;
  final VoidCallback onClearFilters;

  const _EmptyPatternsState({
    required this.hasFilters,
    required this.onCreate,
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
                    hasFilters
                        ? Icons.filter_alt_off_rounded
                        : Icons.spa_outlined,
                    size: 40,
                    color: AdminColors.primary,
                  ),
                ),
                const SizedBox(height: AdminSpacing.md),
                Text(
                  hasFilters
                      ? 'No hay resultados'
                      : 'Todavía no hay patrones',
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
                      ? 'Probá cambiar o limpiar los filtros.'
                      : 'Creá el primer patrón para comenzar el catálogo.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textSoft,
                  ),
                ),
                const SizedBox(height: AdminSpacing.lg),
                if (hasFilters)
                  AdminOutlinedButton(
                    text: 'Limpiar filtros',
                    icon: Icons.filter_alt_off_rounded,
                    onPressed: onClearFilters,
                  )
                else
                  AdminPrimaryButton(
                    text: 'Crear patrón',
                    icon: Icons.add_rounded,
                    onPressed: onCreate,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}