import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/design_system.dart';
import '../app/theme.dart';
import '../controller/dashboard_controller.dart';
import '../models/admin_pattern_model.dart';
import '../models/dashboard_stats_model.dart';
import 'category_form_screen.dart';
import 'pattern_form_screen.dart';

class DashboardHome extends StatelessWidget {
  final DashboardController controller;

  const DashboardHome({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: AdminColors.primary,
          ),
        );
      }

      return RefreshIndicator(
        color: AdminColors.primary,
        onRefresh: controller.refreshDashboard,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final desktop = constraints.maxWidth >= 1100;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(
                compact ? AdminSpacing.md : AdminSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardHeader(
                    refreshing: controller.isRefreshing.value,
                    onRefresh: controller.refreshDashboard,
                  ),

                  const SizedBox(height: AdminSpacing.lg),

                  _StatsGrid(
                    width: constraints.maxWidth,
                    stats: controller.stats.value,
                  ),

                  const SizedBox(height: AdminSpacing.lg),

                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _MonthlyPatternsPanel(
                            points: controller.monthlyPatterns,
                          ),
                        ),
                        const SizedBox(width: AdminSpacing.md),
                        Expanded(
                          flex: 2,
                          child: _CategoryUsagePanel(
                            categories: controller.categoryUsage,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _MonthlyPatternsPanel(
                          points: controller.monthlyPatterns,
                        ),
                        const SizedBox(height: AdminSpacing.md),
                        _CategoryUsagePanel(
                          categories: controller.categoryUsage,
                        ),
                      ],
                    ),

                  const SizedBox(height: AdminSpacing.lg),

                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _RecentPatternsPanel(
                            patterns: controller.recentPatterns,
                          ),
                        ),
                        const SizedBox(width: AdminSpacing.md),
                        const Expanded(
                          flex: 2,
                          child: _QuickActionsPanel(),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _RecentPatternsPanel(
                          patterns: controller.recentPatterns,
                        ),
                        const SizedBox(height: AdminSpacing.md),
                        const _QuickActionsPanel(),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

class _DashboardHeader extends StatelessWidget {
  final bool refreshing;
  final Future<void> Function() onRefresh;

  const _DashboardHeader({
    required this.refreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greetingForHour(now.hour);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AdminColors.textDark,
                ),
              ),
              const SizedBox(height: AdminSpacing.xs),
              Text(
                'Este es el resumen general de Meraki.',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textSoft,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Actualizar dashboard',
          onPressed: refreshing ? null : onRefresh,
          icon: refreshing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AdminColors.primary,
                  ),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  color: AdminColors.primary,
                ),
        ),
      ],
    );
  }

  static String _greetingForHour(int hour) {
    if (hour < 12) {
      return 'Buenos días';
    }

    if (hour < 20) {
      return 'Buenas tardes';
    }

    return 'Buenas noches';
  }
}

class _StatsGrid extends StatelessWidget {
  final double width;
  final DashboardStats stats;

  const _StatsGrid({
    required this.width,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    int columns;

    if (width >= 1250) {
      columns = 4;
    } else if (width >= 650) {
      columns = 2;
    } else {
      columns = 1;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      crossAxisSpacing: AdminSpacing.md,
      mainAxisSpacing: AdminSpacing.md,
      childAspectRatio: columns == 1 ? 3.2 : 2.15,
      children: [
        _StatCard(
          icon: Icons.spa_rounded,
          title: 'Patrones',
          value: stats.totalPatterns.toString(),
          detail: '+${stats.patternsThisMonth} este mes',
        ),
        _StatCard(
          icon: Icons.category_rounded,
          title: 'Categorías',
          value: stats.totalCategories.toString(),
          detail: 'Disponibles',
        ),
        _StatCard(
          icon: Icons.people_alt_outlined,
          title: 'Usuarios',
          value: stats.totalUsers.toString(),
          detail: 'Registrados',
        ),
        _StatCard(
          icon: Icons.favorite_rounded,
          title: 'Favoritos',
          value: stats.totalFavorites.toString(),
          detail: 'Guardados',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: AdminDecorations.card,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: AdminDecorations.primaryTint(
              radius: AdminRadius.medium,
            ),
            child: Icon(
              icon,
              size: 29,
              color: AdminColors.primary,
            ),
          ),
          const SizedBox(width: AdminSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AdminColors.textSoft,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 29,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: AdminColors.textDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  detail,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.primary,
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

class _MonthlyPatternsPanel extends StatelessWidget {
  final List<DashboardMonthlyPoint> points;

  const _MonthlyPatternsPanel({
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Patrones publicados',
      subtitle: 'Actividad durante los últimos seis meses',
      child: points.isEmpty
          ? const _EmptyPanelMessage(
              message: 'Todavía no hay datos mensuales.',
            )
          : SizedBox(
              height: 240,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxValue = points.fold<int>(
                    1,
                    (current, point) =>
                        math.max(current, point.patternsCount),
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: points.map((point) {
                      final ratio = point.patternsCount / maxValue;
                      final barHeight = math.max(
                        12.0,
                        ratio * 150,
                      );

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                point.patternsCount.toString(),
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AdminColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 7),
                              AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 400),
                                width: double.infinity,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: AdminColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                _monthLabel(point.month),
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AdminColors.textSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
    );
  }

  static String _monthLabel(DateTime date) {
    const labels = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return labels[date.month - 1];
  }
}

class _CategoryUsagePanel extends StatelessWidget {
  final List<DashboardCategoryUsage> categories;

  const _CategoryUsagePanel({
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = categories.fold<int>(
      1,
      (current, category) =>
          math.max(current, category.patternsCount),
    );

    return _DashboardPanel(
      title: 'Categorías más utilizadas',
      subtitle: 'Cantidad de patrones por categoría',
      child: categories.isEmpty
          ? const _EmptyPanelMessage(
              message: 'Todavía no hay categorías para mostrar.',
            )
          : Column(
              children: categories.map((category) {
                final progress = category.patternsCount / maxCount;

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AdminSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AdminColors.textDark,
                              ),
                            ),
                          ),
                          Text(
                            category.patternsCount.toString(),
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AdminColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 9,
                          backgroundColor: AdminColors.primaryLight,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                            AdminColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _RecentPatternsPanel extends StatelessWidget {
  final List<AdminPatternModel> patterns;

  const _RecentPatternsPanel({
    required this.patterns,
  });

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Últimos patrones',
      subtitle: 'Contenido agregado recientemente',
      child: patterns.isEmpty
          ? const _EmptyPanelMessage(
              message: 'Todavía no hay patrones cargados.',
            )
          : Column(
              children: patterns.map((pattern) {
                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AdminRadius.small,
                        ),
                        child: Image.network(
                          pattern.imagen,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              width: 52,
                              height: 52,
                              color: AdminColors.primaryLight,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AdminColors.primary,
                              ),
                            );
                          },
                        ),
                      ),
                      title: Text(
                        pattern.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AdminColors.textDark,
                        ),
                      ),
                      subtitle: Text(
                        '${pattern.categoriaNombre} · ${_sourceLabel(pattern.fuente)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textSoft,
                        ),
                      ),
                    ),
                    if (pattern != patterns.last)
                      const Divider(
                        color: AdminBorders.soft,
                      ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  static String _sourceLabel(String source) {
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

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel();

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Acciones rápidas',
      subtitle: 'Atajos para tareas frecuentes',
      child: Column(
        children: [
          _QuickActionTile(
            icon: Icons.add_circle_outline_rounded,
            title: 'Crear patrón',
            subtitle: 'Publicar contenido nuevo',
            onTap: () async {
              final result = await Get.to<bool>(
                () => const PatternFormScreen(),
              );

              if (result == true &&
                  Get.isRegistered<DashboardController>()) {
                await Get.find<DashboardController>()
                    .refreshDashboard();
              }
            },
          ),
          const SizedBox(height: AdminSpacing.sm),
          _QuickActionTile(
            icon: Icons.category_outlined,
            title: 'Crear categoría',
            subtitle: 'Organizar el catálogo',
            onTap: () async {
              final result = await Get.to<bool>(
                () => const CategoryFormScreen(),
              );

              if (result == true &&
                  Get.isRegistered<DashboardController>()) {
                await Get.find<DashboardController>()
                    .refreshDashboard();
              }
            },
          ),
          const SizedBox(height: AdminSpacing.sm),
          _QuickActionTile(
            icon: Icons.refresh_rounded,
            title: 'Actualizar datos',
            subtitle: 'Recargar todas las estadísticas',
            onTap: () {
              Get.find<DashboardController>().refreshDashboard();
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminColors.background,
      borderRadius: BorderRadius.circular(
        AdminRadius.medium,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AdminRadius.medium,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AdminSpacing.md),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: AdminDecorations.primaryTint(
                  radius: AdminRadius.small,
                ),
                child: Icon(
                  icon,
                  color: AdminColors.primary,
                ),
              ),
              const SizedBox(width: AdminSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AdminColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AdminColors.textSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _DashboardPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: AdminDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AdminColors.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AdminColors.textSoft,
            ),
          ),
          const SizedBox(height: AdminSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _EmptyPanelMessage extends StatelessWidget {
  final String message;

  const _EmptyPanelMessage({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AdminSpacing.lg,
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AdminColors.textSoft,
          ),
        ),
      ),
    );
  }
}