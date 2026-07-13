import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_stats_model.dart';

class AnalyticsController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  final isLoading = false.obs;
  final isRefreshing = false.obs;

  final totalPatterns = 0.obs;
  final totalCategories = 0.obs;
  final totalUsers = 0.obs;
  final totalFavorites = 0.obs;

  final patternsThisMonth = 0.obs;
  final usersThisMonth = 0.obs;

  final monthlyPatterns = <DashboardMonthlyPoint>[].obs;
  final monthlyUsers = <DashboardMonthlyPoint>[].obs;
  final categoryUsage = <DashboardCategoryUsage>[].obs;

  final sourceDistribution = <String, int>{}.obs;
  final levelDistribution = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadAnalytics();
  }

  Future<void> loadAnalytics({
    bool showMainLoading = true,
  }) async {
    try {
      if (showMainLoading) {
        isLoading.value = true;
      } else {
        isRefreshing.value = true;
      }

      final results = await Future.wait<dynamic>([
        _safeCount('patterns'),
        _safeCount('categories'),
        _safeCount('profiles'),
        _safeCount('favorites'),
        _countCurrentMonth('patterns'),
        _countCurrentMonth('profiles'),
        _loadMonthlyData(
          table: 'patterns',
          dateColumn: 'created_at',
        ),
        _loadMonthlyData(
          table: 'profiles',
          dateColumn: 'created_at',
        ),
        _loadCategoryUsage(),
        _loadPatternDistributions(),
      ]);

      totalPatterns.value = results[0] as int;
      totalCategories.value = results[1] as int;
      totalUsers.value = results[2] as int;
      totalFavorites.value = results[3] as int;

      patternsThisMonth.value = results[4] as int;
      usersThisMonth.value = results[5] as int;
    } catch (error, stackTrace) {
      debugPrint('Error cargando analytics: $error');
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar(
        'Error',
        'No se pudieron cargar todas las estadísticas',
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<int> _safeCount(String table) async {
    try {
      final response = await supabase
          .from(table)
          .select('id');

      return response.length;
    } catch (error) {
      debugPrint('No se pudo contar $table: $error');
      return 0;
    }
  }

  Future<int> _countCurrentMonth(String table) async {
    try {
      final now = DateTime.now();

      final firstDay = DateTime(
        now.year,
        now.month,
        1,
      );

      final response = await supabase
          .from(table)
          .select('id')
          .gte(
            'created_at',
            firstDay.toIso8601String(),
          );

      return response.length;
    } catch (error) {
      debugPrint(
        'No se pudo contar el mes actual de $table: $error',
      );

      return 0;
    }
  }

  Future<void> _loadMonthlyData({
    required String table,
    required String dateColumn,
  }) async {
    try {
      final now = DateTime.now();

      final firstMonth = DateTime(
        now.year,
        now.month - 5,
        1,
      );

      final response = await supabase
          .from(table)
          .select(dateColumn)
          .gte(
            dateColumn,
            firstMonth.toIso8601String(),
          );

      final counters = <String, int>{};

      for (int index = 0; index < 6; index++) {
        final month = DateTime(
          firstMonth.year,
          firstMonth.month + index,
          1,
        );

        counters[_monthKey(month)] = 0;
      }

      for (final item in response) {
        final rawDate = item[dateColumn]?.toString();
        final parsedDate = DateTime.tryParse(rawDate ?? '');

        if (parsedDate == null) continue;

        final key = _monthKey(parsedDate);

        if (counters.containsKey(key)) {
          counters[key] = (counters[key] ?? 0) + 1;
        }
      }

      final points = <DashboardMonthlyPoint>[];

      for (int index = 0; index < 6; index++) {
        final month = DateTime(
          firstMonth.year,
          firstMonth.month + index,
          1,
        );

        points.add(
          DashboardMonthlyPoint(
            month: month,
            patternsCount:
                counters[_monthKey(month)] ?? 0,
          ),
        );
      }

      if (table == 'patterns') {
        monthlyPatterns.assignAll(points);
      } else if (table == 'profiles') {
        monthlyUsers.assignAll(points);
      }
    } catch (error) {
      debugPrint(
        'No se pudieron cargar datos mensuales de $table: $error',
      );

      if (table == 'patterns') {
        monthlyPatterns.clear();
      } else if (table == 'profiles') {
        monthlyUsers.clear();
      }
    }
  }

  Future<void> _loadCategoryUsage() async {
    try {
      final categoriesResponse = await supabase
          .from('categories')
          .select('id, nombre');

      final patternsResponse = await supabase
          .from('patterns')
          .select('categoria_id');

      final counters = <int, int>{};

      for (final pattern in patternsResponse) {
        final categoryId = pattern['categoria_id'];

        if (categoryId is int) {
          counters[categoryId] =
              (counters[categoryId] ?? 0) + 1;
        }
      }

      final result = categoriesResponse
          .map<DashboardCategoryUsage>(
            (category) {
              final id = category['id'] as int;

              return DashboardCategoryUsage(
                categoryId: id,
                categoryName:
                    category['nombre']?.toString() ??
                        'Sin categoría',
                patternsCount: counters[id] ?? 0,
              );
            },
          )
          .toList();

      result.sort(
        (a, b) =>
            b.patternsCount.compareTo(a.patternsCount),
      );

      categoryUsage.assignAll(result.take(8));
    } catch (error) {
      debugPrint(
        'No se pudo cargar el uso de categorías: $error',
      );

      categoryUsage.clear();
    }
  }

  Future<void> _loadPatternDistributions() async {
    try {
      final response = await supabase
          .from('patterns')
          .select('fuente, nivel');

      final sourceCounter = <String, int>{};
      final levelCounter = <String, int>{};

      for (final item in response) {
        final source =
            item['fuente']?.toString().trim().toLowerCase();

        final level =
            item['nivel']?.toString().trim();

        if (source != null && source.isNotEmpty) {
          sourceCounter[source] =
              (sourceCounter[source] ?? 0) + 1;
        }

        if (level != null && level.isNotEmpty) {
          levelCounter[level] =
              (levelCounter[level] ?? 0) + 1;
        }
      }

      sourceDistribution.assignAll(sourceCounter);
      levelDistribution.assignAll(levelCounter);
    } catch (error) {
      debugPrint(
        'No se pudieron cargar las distribuciones: $error',
      );

      sourceDistribution.clear();
      levelDistribution.clear();
    }
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');

    return '${date.year}-$month';
  }

  Future<void> refreshAnalytics() async {
    await loadAnalytics(
      showMainLoading: false,
    );
  }
}