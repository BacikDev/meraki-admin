import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/design_system.dart';
import '../app/theme.dart';
import '../controller/analytics_controller.dart';
import '../models/dashboard_stats_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final AnalyticsController controller;

  @override
  void initState() {
    super.initState();

    controller = Get.isRegistered<AnalyticsController>()
        ? Get.find<AnalyticsController>()
        : Get.put(AnalyticsController());
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final isRefreshing = controller.isRefreshing.value;

      final totalPatterns = controller.totalPatterns.value;
      final totalCategories = controller.totalCategories.value;
      final totalUsers = controller.totalUsers.value;
      final totalFavorites = controller.totalFavorites.value;

      final patternsThisMonth = controller.patternsThisMonth.value;
      final usersThisMonth = controller.usersThisMonth.value;

      final monthlyPatterns = controller.monthlyPatterns.toList();
      final monthlyUsers = controller.monthlyUsers.toList();
      final categoryUsage = controller.categoryUsage.toList();

      final sourceDistribution =
          Map<String, int>.from(controller.sourceDistribution);

      final levelDistribution =
          Map<String, int>.from(controller.levelDistribution);

      if (isLoading) {
        return const Center(
          child: CircularProgressIndicator(
            color: AdminColors.primary,
          ),
        );
      }

      return RefreshIndicator(
        color: AdminColors.primary,
        onRefresh: controller.refreshAnalytics,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final desktop = constraints.maxWidth >= 1150;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(
                compact ? AdminSpacing.md : AdminSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnalyticsHeader(
                    isRefreshing: isRefreshing,
                    onRefresh: controller.refreshAnalytics,
                  ),

                  const SizedBox(height: AdminSpacing.lg),

                  _AnalyticsStatsGrid(
                    width: constraints.maxWidth,
                    totalPatterns: totalPatterns,
                    totalCategories: totalCategories,
                    totalUsers: totalUsers,
                    totalFavorites: totalFavorites,
                    patternsThisMonth: patternsThisMonth,
                    usersThisMonth: usersThisMonth,
                  ),

                  const SizedBox(height: AdminSpacing.lg),

                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _MonthlyChartPanel(
                            title: 'Patrones publicados',
                            subtitle:
                                'Evolución durante los últimos seis meses',
                            points: monthlyPatterns,
                          ),
                        ),
                        const SizedBox(width: AdminSpacing.md),
                        Expanded(
                          child: _MonthlyChartPanel(
                            title: 'Usuarios registrados',
                            subtitle:
                                'Nuevos usuarios durante los últimos seis meses',
                            points: monthlyUsers,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _MonthlyChartPanel(
                          title: 'Patrones publicados',
                          subtitle:
                              'Evolución durante los últimos seis meses',
                          points: monthlyPatterns,
                        ),
                        const SizedBox(height: AdminSpacing.md),
                        _MonthlyChartPanel(
                          title: 'Usuarios registrados',
                          subtitle:
                              'Nuevos usuarios durante los últimos seis meses',
                          points: monthlyUsers,
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
                          child: _CategoryUsagePanel(
                            categories: categoryUsage,
                          ),
                        ),
                        const SizedBox(width: AdminSpacing.md),
                        Expanded(
                          flex: 2,
                          child: _DistributionPanel(
                            title: 'Distribución por fuente',
                            subtitle:
                                'Plataformas de origen de los patrones',
                            values: sourceDistribution,
                            labelBuilder: _sourceLabel,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _CategoryUsagePanel(
                          categories: categoryUsage,
                        ),
                        const SizedBox(height: AdminSpacing.md),
                        _DistributionPanel(
                          title: 'Distribución por fuente',
                          subtitle:
                              'Plataformas de origen de los patrones',
                          values: sourceDistribution,
                          labelBuilder: _sourceLabel,
                        ),
                      ],
                    ),

                  const SizedBox(height: AdminSpacing.lg),

                  _DistributionPanel(
                    title: 'Distribución por dificultad',
                    subtitle:
                        'Cantidad de patrones por nivel de complejidad',
                    values: levelDistribution,
                    labelBuilder: (value) => value,
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
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

class _AnalyticsHeader extends StatelessWidget {
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  const _AnalyticsHeader({
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AdminColors.textDark,
                ),
              ),
              const SizedBox(height: AdminSpacing.xs),
              Text(
                'Analizá el crecimiento y el comportamiento del contenido de Meraki.',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textSoft,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Actualizar estadísticas',
          onPressed: isRefreshing ? null : onRefresh,
          icon: isRefreshing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
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
}

class _AnalyticsStatsGrid extends StatelessWidget {
  final double width;

  final int totalPatterns;
  final int totalCategories;
  final int totalUsers;
  final int totalFavorites;
  final int patternsThisMonth;
  final int usersThisMonth;

  const _AnalyticsStatsGrid({
    required this.width,
    required this.totalPatterns,
    required this.totalCategories,
    required this.totalUsers,
    required this.totalFavorites,
    required this.patternsThisMonth,
    required this.usersThisMonth,
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
      childAspectRatio: columns == 1 ? 3.1 : 2.1,
      children: [
        _AnalyticsStatCard(
          icon: Icons.spa_rounded,
          title: 'Patrones',
          value: totalPatterns,
          detail: '+$patternsThisMonth este mes',
        ),
        _AnalyticsStatCard(
          icon: Icons.category_rounded,
          title: 'Categorías',
          value: totalCategories,
          detail: 'Categorías disponibles',
        ),
        _AnalyticsStatCard(
          icon: Icons.people_alt_outlined,
          title: 'Usuarios',
          value: totalUsers,
          detail: '+$usersThisMonth este mes',
        ),
        _AnalyticsStatCard(
          icon: Icons.favorite_rounded,
          title: 'Favoritos',
          value: totalFavorites,
          detail: 'Patrones guardados',
        ),
      ],
    );
  }
}

class _AnalyticsStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final String detail;

  const _AnalyticsStatCard({
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
                  value.toString(),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _MonthlyChartPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<DashboardMonthlyPoint> points;

  const _MonthlyChartPanel({
    required this.title,
    required this.subtitle,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return _AnalyticsPanel(
      title: title,
      subtitle: subtitle,
      child: points.isEmpty
          ? const _EmptyAnalyticsMessage(
              message: 'Todavía no hay datos suficientes.',
            )
          : SizedBox(
              height: 245,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxValue = points.fold<int>(
                    1,
                    (current, point) {
                      return math.max(
                        current,
                        point.patternsCount,
                      );
                    },
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: points.map((point) {
                      final ratio = point.patternsCount / maxValue;
                      final height = math.max(
                        12.0,
                        ratio * 155,
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
                                    const Duration(milliseconds: 350),
                                height: height,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AdminColors.primary,
                                  borderRadius: BorderRadius.circular(
                                    AdminRadius.small,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
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

  String _monthLabel(DateTime date) {
    const months = [
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

    return months[date.month - 1];
  }
}

class _CategoryUsagePanel extends StatelessWidget {
  final List<DashboardCategoryUsage> categories;

  const _CategoryUsagePanel({
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = categories.fold<int>(
      1,
      (current, category) {
        return math.max(
          current,
          category.patternsCount,
        );
      },
    );

    return _AnalyticsPanel(
      title: 'Categorías más utilizadas',
      subtitle: 'Cantidad de patrones dentro de cada categoría',
      child: categories.isEmpty
          ? const _EmptyAnalyticsMessage(
              message: 'No hay categorías para analizar.',
            )
          : Column(
              children: categories.map((category) {
                final progress =
                    category.patternsCount / maxValue;

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
                          backgroundColor:
                              AdminColors.primaryLight,
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

class _DistributionPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Map<String, int> values;
  final String Function(String value) labelBuilder;

  const _DistributionPanel({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    final total = entries.fold<int>(
      0,
      (current, entry) => current + entry.value,
    );

    return _AnalyticsPanel(
      title: title,
      subtitle: subtitle,
      child: entries.isEmpty
          ? const _EmptyAnalyticsMessage(
              message: 'Todavía no hay datos disponibles.',
            )
          : Column(
              children: entries.map((entry) {
                final percentage = total == 0
                    ? 0.0
                    : entry.value / total;

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AdminSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: AdminDecorations.primaryTint(
                          radius: AdminRadius.small,
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: AdminColors.primary,
                        ),
                      ),
                      const SizedBox(width: AdminSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    labelBuilder(entry.key),
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: AdminColors.textDark,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(percentage * 100).toStringAsFixed(1)}%',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: AdminColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: percentage,
                                minHeight: 8,
                                backgroundColor:
                                    AdminColors.primaryLight,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  AdminColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AdminSpacing.sm),
                      Text(
                        entry.value.toString(),
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AdminColors.textSoft,
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

class _AnalyticsPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _AnalyticsPanel({
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

class _EmptyAnalyticsMessage extends StatelessWidget {
  final String message;

  const _EmptyAnalyticsMessage({
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