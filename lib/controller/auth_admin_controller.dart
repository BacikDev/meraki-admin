import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthAdminController extends GetxController {
  final supabase = Supabase.instance.client;

  final isLoading = false.obs;
  final isLoggedIn = false.obs;
  final isAdmin = false.obs;

  User? get currentUser => supabase.auth.currentUser;

  @override
  void onInit() {
    super.onInit();
    checkSession();

    supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      isLoggedIn.value = session != null;

      if (session != null) {
        await checkAdminRole();
      } else {
        isAdmin.value = false;
      }
    });
  }

  Future<void> checkSession() async {
    isLoggedIn.value = supabase.auth.currentSession != null;

    if (isLoggedIn.value) {
      await checkAdminRole();
    }
  }

  Future<void> checkAdminRole() async {
    try {
      final user = currentUser;

      if (user == null) {
        isAdmin.value = false;
        return;
      }

      final response = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      isAdmin.value = response?['role'] == 'admin';

      if (!isAdmin.value) {
        Get.snackbar(
          'Acceso denegado',
          'Tu usuario no tiene permisos de administrador',
        );
      }
    } catch (e) {
      isAdmin.value = false;
      Get.snackbar('Error', 'No se pudo verificar el rol de administrador');
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await checkAdminRole();
    } catch (e) {
      Get.snackbar('Error', 'Correo o contraseña incorrectos');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    isLoggedIn.value = false;
    isAdmin.value = false;
  }
}