import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_category_model.dart';

class CategoriesAdminController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  final isLoading = false.obs;
  final categories = <AdminCategoryModel>[].obs;
  final filteredCategories = <AdminCategoryModel>[].obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      isLoading.value = true;

      final response = await supabase
          .from('categories')
          .select('''
            id,
            nombre,
            imagen,
            descripcion,
            created_at
          ''')
          .order('nombre', ascending: true);

      categories.assignAll(
        response.map<AdminCategoryModel>(
          (item) => AdminCategoryModel.fromJson(item),
        ),
      );

      _applyFilter();
    } catch (error, stackTrace) {
      debugPrint('Error cargando categorías: $error');
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar(
        'Error',
        'No se pudieron cargar las categorías',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createCategory({
    required String nombre,
    String imagen = '',
    String descripcion = '',
  }) async {
    try {
      await supabase.from('categories').insert({
        'nombre': nombre.trim(),
        'imagen': imagen.trim(),
        'descripcion': descripcion.trim(),
      });

      await loadCategories();

      return true;
    } catch (error, stackTrace) {
      debugPrint('Error creando categoría: $error');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  Future<bool> updateCategory({
    required int id,
    required String nombre,
    String imagen = '',
    String descripcion = '',
  }) async {
    try {
      await supabase
          .from('categories')
          .update({
            'nombre': nombre.trim(),
            'imagen': imagen.trim(),
            'descripcion': descripcion.trim(),
          })
          .eq('id', id);

      await loadCategories();

      return true;
    } catch (error, stackTrace) {
      debugPrint('Error actualizando categoría: $error');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      isLoading.value = true;

      final linkedPatterns = await supabase
          .from('patterns')
          .select('id')
          .eq('categoria_id', id)
          .limit(1);

      if (linkedPatterns.isNotEmpty) {
        Get.snackbar(
          'No se puede eliminar',
          'Esta categoría tiene patrones asociados',
        );

        return false;
      }

      await supabase.from('categories').delete().eq('id', id);

      categories.removeWhere(
        (category) => category.id == id,
      );

      _applyFilter();

      Get.snackbar(
        'Categoría eliminada',
        'La categoría fue eliminada correctamente',
      );

      return true;
    } catch (error, stackTrace) {
      debugPrint('Error eliminando categoría: $error');
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar(
        'Error',
        'No se pudo eliminar la categoría',
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void searchCategories(String value) {
    searchQuery.value = value.trim();
    _applyFilter();
  }

  void clearSearch() {
    searchQuery.value = '';
    _applyFilter();
  }

  void _applyFilter() {
    final query = searchQuery.value.toLowerCase();

    if (query.isEmpty) {
      filteredCategories.assignAll(categories);
      return;
    }

    filteredCategories.assignAll(
      categories.where((category) {
        final nameMatches =
            category.nombre.toLowerCase().contains(query);

        final descriptionMatches =
            (category.descripcion ?? '')
                .toLowerCase()
                .contains(query);

        return nameMatches || descriptionMatches;
      }),
    );
  }

  AdminCategoryModel? getCategoryById(int id) {
    try {
      return categories.firstWhere(
        (category) => category.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshCategories() async {
    await loadCategories();
  }
}