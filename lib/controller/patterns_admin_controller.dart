import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_pattern_model.dart';
import '../services/storage_service.dart';

class PatternsAdminController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;
  final StorageService storageService = StorageService.instance;

  final isLoading = false.obs;
  final isDeleting = false.obs;

  final patterns = <AdminPatternModel>[].obs;
  final filteredPatterns = <AdminPatternModel>[].obs;

  final categories = <Map<String, dynamic>>[].obs;

  final searchQuery = ''.obs;
  final selectedCategoryId = RxnInt();
  final selectedLevel = RxnString();
  final selectedSource = RxnString();

  final sortOption = 'Más recientes'.obs;

  final levels = const [
    'Fácil',
    'Medio',
    'Avanzado',
  ];

  final sources = const [
    'youtube',
    'instagram',
    'tiktok',
  ];

  final sortOptions = const [
    'Más recientes',
    'Más antiguos',
    'Título A-Z',
    'Título Z-A',
    'Orden manual',
  ];

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      loadCategories(),
      loadPatterns(),
    ]);
  }

  Future<void> loadPatterns() async {
    try {
      isLoading.value = true;

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
          );

      patterns.assignAll(
        response.map<AdminPatternModel>(
          (item) => AdminPatternModel.fromJson(item),
        ),
      );

      applyFilters();
    } catch (error, stackTrace) {
      debugPrint('Error cargando patrones: $error');
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar(
        'Error',
        'No se pudieron cargar los patrones',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCategories() async {
    try {
      final response = await supabase
          .from('categories')
          .select('id, nombre')
          .order(
            'nombre',
            ascending: true,
          );

      categories.assignAll(
        List<Map<String, dynamic>>.from(response),
      );
    } catch (error, stackTrace) {
      debugPrint('Error cargando categorías: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void updateSearch(String value) {
    searchQuery.value = value.trim();
    applyFilters();
  }

  void updateCategory(int? categoryId) {
    selectedCategoryId.value = categoryId;
    applyFilters();
  }

  void updateLevel(String? level) {
    selectedLevel.value = level;
    applyFilters();
  }

  void updateSource(String? source) {
    selectedSource.value = source;
    applyFilters();
  }

  void updateSort(String option) {
    sortOption.value = option;
    applyFilters();
  }

  void applyFilters() {
    Iterable<AdminPatternModel> result = patterns;

    final query = searchQuery.value.trim().toLowerCase();
    final categoryId = selectedCategoryId.value;
    final level = selectedLevel.value;
    final source = selectedSource.value;

    if (query.isNotEmpty) {
      result = result.where((pattern) {
        return pattern.titulo.toLowerCase().contains(query) ||
            pattern.descripcion.toLowerCase().contains(query) ||
            pattern.categoriaNombre
                .toLowerCase()
                .contains(query) ||
            pattern.nivel.toLowerCase().contains(query) ||
            pattern.fuente.toLowerCase().contains(query);
      });
    }

    if (categoryId != null) {
      result = result.where(
        (pattern) => pattern.categoriaId == categoryId,
      );
    }

    if (level != null && level.trim().isNotEmpty) {
      result = result.where(
        (pattern) =>
            pattern.nivel.toLowerCase() ==
            level.toLowerCase(),
      );
    }

    if (source != null && source.trim().isNotEmpty) {
      result = result.where(
        (pattern) =>
            pattern.fuente.toLowerCase() ==
            source.toLowerCase(),
      );
    }

    final sorted = result.toList();

    switch (sortOption.value) {
      case 'Más antiguos':
        sorted.sort((a, b) {
          final dateA = a.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);

          final dateB = b.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);

          return dateA.compareTo(dateB);
        });
        break;

      case 'Título A-Z':
        sorted.sort(
          (a, b) => a.titulo.toLowerCase().compareTo(
                b.titulo.toLowerCase(),
              ),
        );
        break;

      case 'Título Z-A':
        sorted.sort(
          (a, b) => b.titulo.toLowerCase().compareTo(
                a.titulo.toLowerCase(),
              ),
        );
        break;

      case 'Orden manual':
        sorted.sort((a, b) {
          final orderResult = a.orden.compareTo(b.orden);

          if (orderResult != 0) {
            return orderResult;
          }

          return a.titulo.toLowerCase().compareTo(
                b.titulo.toLowerCase(),
              );
        });
        break;

      case 'Más recientes':
      default:
        sorted.sort((a, b) {
          final dateA = a.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);

          final dateB = b.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);

          return dateB.compareTo(dateA);
        });
    }

    filteredPatterns.assignAll(sorted);
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedCategoryId.value = null;
    selectedLevel.value = null;
    selectedSource.value = null;
    sortOption.value = 'Más recientes';

    applyFilters();
  }

  bool get hasActiveFilters {
    return searchQuery.value.isNotEmpty ||
        selectedCategoryId.value != null ||
        selectedLevel.value != null ||
        selectedSource.value != null ||
        sortOption.value != 'Más recientes';
  }

  int get totalResults => filteredPatterns.length;

  Future<bool> deletePattern(
    AdminPatternModel pattern,
  ) async {
    try {
      isDeleting.value = true;

      await supabase
          .from('patterns')
          .delete()
          .eq('id', pattern.id);

      if (pattern.imagen.trim().isNotEmpty) {
        try {
          await storageService.deletePatternImage(
            pattern.imagen,
          );
        } catch (error, stackTrace) {
          debugPrint(
            'El patrón fue eliminado, pero no se pudo borrar su imagen: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
        }
      }

      patterns.removeWhere(
        (item) => item.id == pattern.id,
      );

      applyFilters();

      Get.snackbar(
        'Patrón eliminado',
        'El patrón fue eliminado correctamente',
      );

      return true;
    } catch (error, stackTrace) {
      debugPrint('Error eliminando patrón: $error');
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar(
        'Error',
        'No se pudo eliminar el patrón',
      );

      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  Future<bool> duplicatePattern(
    AdminPatternModel pattern,
  ) async {
    try {
      isLoading.value = true;

      await supabase.from('patterns').insert({
        'titulo': '${pattern.titulo} - Copia',
        'descripcion': pattern.descripcion,
        'imagen': pattern.imagen,
        'categoria_id': pattern.categoriaId,
        'nivel': pattern.nivel,
        'fuente': pattern.fuente,
        'url': pattern.url,
        'publicado': false,
        'destacado': false,
        'orden': pattern.orden,
      });

      await loadPatterns();

      Get.snackbar(
        'Patrón duplicado',
        'La copia fue creada como no publicada',
      );

      return true;
    } catch (error, stackTrace) {
      debugPrint('Error duplicando patrón: $error');
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar(
        'Error',
        'No se pudo duplicar el patrón',
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPatterns() async {
    await Future.wait([
      loadCategories(),
      loadPatterns(),
    ]);
  }

  String categoryNameById(int? id) {
    if (id == null) {
      return 'Todas las categorías';
    }

    try {
      final category = categories.firstWhere(
        (item) => item['id'] == id,
      );

      return category['nombre']?.toString() ??
          'Sin categoría';
    } catch (_) {
      return 'Sin categoría';
    }
  }
}