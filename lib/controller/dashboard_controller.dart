import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_pattern_model.dart';
import '../models/dashboard_stats_model.dart';

class DashboardController extends GetxController {
  final SupabaseClient supabase =
      Supabase.instance.client;

  final isLoading = false.obs;
  final isRefreshing = false.obs;

  final stats = const DashboardStats().obs;

  final recentPatterns =
      <AdminPatternModel>[].obs;

  final categoryUsage =
      <DashboardCategoryUsage>[].obs;

  final monthlyPatterns =
      <DashboardMonthlyPoint>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard({
    bool showMainLoading = true,
  }) async {
    try {
      if (showMainLoading) {
        isLoading.value = true;
      } else {
        isRefreshing.value = true;
      }

      final results =
          await Future.wait<dynamic>([
        _safeCount('patterns'),
        _safeCount('categories'),
        _safeCount('profiles'),
        _safeCount('favorites'),
        _loadPatternsThisMonth(),
        _loadRecentPatterns(),
        _loadCategoryUsage(),
        _loadMonthlyPatterns(),
      ]);

      stats.value = DashboardStats(
        totalPatterns: results[0] as int,
        totalCategories: results[1] as int,
        totalUsers: results[2] as int,
        totalFavorites: results[3] as int,
        patternsThisMonth:
            results[4] as int,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Error cargando dashboard: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      Get.snackbar(
        'Error',
        'No se pudo cargar toda la información del dashboard',
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<int> _safeCount(
    String table,
  ) async {
    try {
      final response = await supabase
          .from(table)
          .select('id');

      return response.length;
    } catch (error) {
      debugPrint(
        'No se pudo contar la tabla $table: $error',
      );

      return 0;
    }
  }

  Future<int>
      _loadPatternsThisMonth() async {
    try {
      final now = DateTime.now();

      final firstDay = DateTime(
        now.year,
        now.month,
        1,
      );

      final response = await supabase
          .from('patterns')
          .select('id')
          .gte(
            'created_at',
            firstDay.toIso8601String(),
          );

      return response.length;
    } catch (error) {
      debugPrint(
        'No se pudieron cargar los patrones del mes: $error',
      );

      return 0;
    }
  }

  Future<void> _loadRecentPatterns() async {
    try {
      final response = await supabase
          .from('patterns')
          .select('''
            id,
            titulo,
            descripcion,
            imagen,
            nivel,
            fuente,
            url,
            categoria_id,
            publicado,
            destacado,
            orden,
            created_at,
            categories (
              nombre
            )
          ''')
          .order(
            'created_at',
            ascending: false,
          )
          .limit(5);

      recentPatterns.assignAll(
        response.map<AdminPatternModel>(
          (item) =>
              AdminPatternModel.fromJson(item),
        ),
      );
    } catch (error) {
      debugPrint(
        'No se pudieron cargar los patrones recientes: $error',
      );

      recentPatterns.clear();
    }
  }

  Future<void> _loadCategoryUsage() async {
    try {
      final categoriesResponse =
          await supabase
              .from('categories')
              .select('id, nombre');

      final patternsResponse =
          await supabase
              .from('patterns')
              .select('categoria_id');

      final counters = <int, int>{};

      for (final pattern
          in patternsResponse) {
        final categoryId =
            pattern['categoria_id'];

        if (categoryId is int) {
          counters[categoryId] =
              (counters[categoryId] ?? 0) +
                  1;
        }
      }

      final result = categoriesResponse
          .map<DashboardCategoryUsage>(
        (category) {
          final id = category['id'] as int;

          return DashboardCategoryUsage(
            categoryId: id,
            categoryName:
                category['nombre']
                        ?.toString() ??
                    'Sin categoría',
            patternsCount:
                counters[id] ?? 0,
          );
        },
      ).toList();

      result.sort(
        (a, b) => b.patternsCount
            .compareTo(a.patternsCount),
      );

      categoryUsage.assignAll(
        result.take(5),
      );
    } catch (error) {
      debugPrint(
        'No se pudo cargar el uso de categorías: $error',
      );

      categoryUsage.clear();
    }
  }

  Future<void>
      _loadMonthlyPatterns() async {
    try {
      final now = DateTime.now();

      final firstMonth = DateTime(
        now.year,
        now.month - 5,
        1,
      );

      final response = await supabase
          .from('patterns')
          .select('created_at')
          .gte(
            'created_at',
            firstMonth.toIso8601String(),
          );

      final counters = <String, int>{};

      for (int index = 0;
          index < 6;
          index++) {
        final month = DateTime(
          firstMonth.year,
          firstMonth.month + index,
          1,
        );

        counters[_monthKey(month)] = 0;
      }

      for (final item in response) {
        final rawDate =
            item['created_at']?.toString();

        final date =
            DateTime.tryParse(rawDate ?? '');

        if (date == null) continue;

        final key = _monthKey(date);

        if (counters.containsKey(key)) {
          counters[key] =
              (counters[key] ?? 0) + 1;
        }
      }

      final points =
          <DashboardMonthlyPoint>[];

      for (int index = 0;
          index < 6;
          index++) {
        final month = DateTime(
          firstMonth.year,
          firstMonth.month + index,
          1,
        );

        points.add(
          DashboardMonthlyPoint(
            month: month,
            patternsCount:
                counters[_monthKey(month)] ??
                    0,
          ),
        );
      }

      monthlyPatterns.assignAll(points);
    } catch (error) {
      debugPrint(
        'No se pudieron cargar las estadísticas mensuales: $error',
      );

      monthlyPatterns.clear();
    }
  }

  String _monthKey(DateTime date) {
    final month =
        date.month.toString().padLeft(2, '0');

    return '${date.year}-$month';
  }

  Future<void> refreshDashboard() async {
    await loadDashboard(
      showMainLoading: false,
    );
  }
}