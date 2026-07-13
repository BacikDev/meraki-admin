import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_user_model.dart';

class UsersAdminController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  final isLoading = false.obs;
  final isUpdating = false.obs;

  final users = <AdminUserModel>[].obs;
  final filteredUsers = <AdminUserModel>[].obs;

  final searchQuery = ''.obs;
  final selectedRole = RxnString();
  final selectedStatus = RxnBool();

  final roles = const <String>[
    'admin',
    'editor',
    'user',
  ];

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;

      final response = await supabase
          .from('profiles')
          .select('''
            id,
            nombre,
            email,
            avatar_url,
            role,
            is_active,
            created_at,
            updated_at
          ''')
          .order('created_at', ascending: false);

      users.assignAll(
        response.map<AdminUserModel>(
          (item) => AdminUserModel.fromJson(item),
        ),
      );

      applyFilters();
    } catch (error, stackTrace) {
      debugPrint('Error cargando usuarios: $error');
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar(
        'Error',
        'No se pudieron cargar los usuarios',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearch(String value) {
    searchQuery.value = value.trim();
    applyFilters();
  }

  void updateRoleFilter(String? value) {
    selectedRole.value = value;
    applyFilters();
  }

  void updateStatusFilter(bool? value) {
    selectedStatus.value = value;
    applyFilters();
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedRole.value = null;
    selectedStatus.value = null;

    applyFilters();
  }

  void applyFilters() {
    Iterable<AdminUserModel> result = users;

    final query = searchQuery.value.toLowerCase();
    final role = selectedRole.value;
    final status = selectedStatus.value;

    if (query.isNotEmpty) {
      result = result.where((user) {
        return user.nombre.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            user.roleLabel.toLowerCase().contains(query);
      });
    }

    if (role != null) {
      result = result.where(
        (user) => user.role.toLowerCase() == role.toLowerCase(),
      );
    }

    if (status != null) {
      result = result.where(
        (user) => user.isActive == status,
      );
    }

    filteredUsers.assignAll(result);
  }

  bool get hasActiveFilters {
    return searchQuery.value.isNotEmpty ||
        selectedRole.value != null ||
        selectedStatus.value != null;
  }

  int get totalResults => filteredUsers.length;

  Future<bool> updateUserRole({
    required AdminUserModel user,
    required String role,
  }) async {
    if (!roles.contains(role)) {
      Get.snackbar(
        'Rol inválido',
        'El rol seleccionado no está permitido',
      );

      return false;
    }

    try {
      isUpdating.value = true;

      await supabase
          .from('profiles')
          .update({
            'role': role,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      _replaceUser(
        user.copyWith(
          role: role,
          updatedAt: DateTime.now(),
        ),
      );

      Get.snackbar(
        'Rol actualizado',
        '${user.displayName} ahora tiene el rol ${_roleLabel(role)}',
      );

      return true;
    } catch (error, stackTrace) {
      debugPrint('Error actualizando rol: $error');
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar(
        'Error',
        'No se pudo actualizar el rol',
      );

      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> updateUserStatus({
    required AdminUserModel user,
    required bool isActive,
  }) async {
    try {
      isUpdating.value = true;

      await supabase
          .from('profiles')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      _replaceUser(
        user.copyWith(
          isActive: isActive,
          updatedAt: DateTime.now(),
        ),
      );

      Get.snackbar(
        isActive ? 'Usuario activado' : 'Usuario bloqueado',
        isActive
            ? '${user.displayName} puede volver a utilizar la aplicación'
            : '${user.displayName} fue bloqueado correctamente',
      );

      return true;
    } catch (error, stackTrace) {
      debugPrint('Error actualizando estado: $error');
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar(
        'Error',
        'No se pudo actualizar el estado del usuario',
      );

      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  void _replaceUser(AdminUserModel updatedUser) {
    final index = users.indexWhere(
      (user) => user.id == updatedUser.id,
    );

    if (index == -1) {
      return;
    }

    users[index] = updatedUser;
    users.refresh();

    applyFilters();
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'editor':
        return 'Editor';
      default:
        return 'Usuario';
    }
  }

  Future<void> refreshUsers() async {
    await loadUsers();
  }
}