import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/design_system.dart';
import '../app/theme.dart';
import '../controller/categories_admin_controller.dart';
import '../models/admin_category_model.dart';
import '../services/storage_service.dart';
import '../widgets/buttons/admin_outlined_button.dart';
import '../widgets/buttons/admin_primary_button.dart';
import '../widgets/form/form_header.dart';
import '../widgets/form/image_preview.dart';
import '../widgets/form/image_uploader.dart';
import '../widgets/form/section_title.dart';
import '../widgets/inputs/admin_text_field.dart';
import '../widgets/layout/admin_form_page.dart';

class CategoryFormScreen extends StatefulWidget {
  final AdminCategoryModel? category;

  const CategoryFormScreen({
    super.key,
    this.category,
  });

  @override
  State<CategoryFormScreen> createState() =>
      _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final StorageService storageService = StorageService.instance;

  late final CategoriesAdminController categoriesController;

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  final TextEditingController imageController =
      TextEditingController();

  bool isLoading = false;
  bool uploadingImage = false;
  bool isClosing = false;

  String? originalImageUrl;
  String? uploadedImageUrl;

  bool get isEditing => widget.category != null;

  bool get isBusy => isLoading || uploadingImage;

  @override
  void initState() {
    super.initState();

    categoriesController =
        Get.isRegistered<CategoriesAdminController>()
            ? Get.find<CategoriesAdminController>()
            : Get.put(CategoriesAdminController());

    _loadCategoryData();
  }

  void _loadCategoryData() {
    final category = widget.category;

    if (category == null) return;

    nameController.text = category.nombre;
    descriptionController.text = category.descripcion ?? '';
    imageController.text = category.imagen;

    originalImageUrl = category.imagen;
  }

  Future<void> _pickImage() async {
    if (isBusy) return;

    try {
      setState(() {
        uploadingImage = true;
      });

      final newImageUrl =
          await storageService.pickAndUploadCategoryImage();

      if (newImageUrl == null || !mounted) return;

      final previousTemporaryImage = uploadedImageUrl;

      if (previousTemporaryImage != null &&
          previousTemporaryImage != newImageUrl) {
        await _tryDeleteImage(previousTemporaryImage);
      }

      setState(() {
        uploadedImageUrl = newImageUrl;
        imageController.text = newImageUrl;
      });

      Get.snackbar(
        'Imagen subida',
        'La imagen de la categoría se cargó correctamente',
        backgroundColor: AdminColors.primaryLight,
        colorText: AdminColors.textDark,
      );
    } catch (error) {
      _showError('No se pudo subir la imagen');
    } finally {
      if (mounted) {
        setState(() {
          uploadingImage = false;
        });
      }
    }
  }

  Future<void> _removeSelectedImage() async {
    if (isBusy) return;

    final temporaryImage = uploadedImageUrl;

    setState(() {
      imageController.clear();
      uploadedImageUrl = null;
    });

    if (temporaryImage != null) {
      await _tryDeleteImage(temporaryImage);
    }
  }

  Future<void> _cancelForm() async {
    if (isBusy || isClosing) return;

    isClosing = true;

    final temporaryImage = uploadedImageUrl;
    uploadedImageUrl = null;

    if (temporaryImage != null) {
      await _tryDeleteImage(temporaryImage);
    }

    if (mounted) {
      Get.back();
    }
  }

  Future<void> _saveCategory() async {
    FocusScope.of(context).unfocus();

    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (imageController.text.trim().isEmpty) {
      Get.snackbar(
        'Imagen requerida',
        'Seleccioná una imagen para la categoría',
        backgroundColor: AdminColors.primaryLight,
        colorText: AdminColors.textDark,
      );
      return;
    }

    if (isLoading || uploadingImage) return;

    try {
      setState(() {
        isLoading = true;
      });

      final nombre = nameController.text.trim();
      final descripcion = descriptionController.text.trim();
      final imagen = imageController.text.trim();

      final bool success;

      if (isEditing) {
        success = await categoriesController.updateCategory(
          id: widget.category!.id,
          nombre: nombre,
          descripcion: descripcion,
          imagen: imagen,
        );

        if (success) {
          await _deletePreviousImageAfterUpdate();
        }
      } else {
        success = await categoriesController.createCategory(
          nombre: nombre,
          descripcion: descripcion,
          imagen: imagen,
        );
      }

      if (!success) {
        _showError(
          isEditing
              ? 'La categoría no pudo actualizarse'
              : 'La categoría no pudo crearse',
        );
        return;
      }

      // La imagen ya quedó asociada al registro.
      uploadedImageUrl = null;
      isClosing = true;

      if (!mounted) return;

      // Cerramos primero el formulario.
      Navigator.of(context).pop(true);

      // Mostramos la confirmación desde la pantalla anterior.
      Future.delayed(const Duration(milliseconds: 250), () {
        Get.snackbar(
          isEditing
              ? 'Categoría actualizada'
              : 'Categoría creada',
          isEditing
              ? 'Los cambios fueron guardados correctamente'
              : 'La categoría fue creada correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AdminColors.primaryLight,
          colorText: AdminColors.textDark,
          margin: const EdgeInsets.all(18),
          duration: const Duration(seconds: 4),
        );
      });
    } catch (error, stackTrace) {
      debugPrint('Error guardando categoría: $error');
      debugPrintStack(stackTrace: stackTrace);

      _showError(
        isEditing
            ? 'No se pudo actualizar la categoría'
            : 'No se pudo crear la categoría',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePreviousImageAfterUpdate() async {
    final oldImage = originalImageUrl;
    final newImage = uploadedImageUrl;

    if (newImage == null ||
        oldImage == null ||
        oldImage.trim().isEmpty ||
        oldImage == newImage) {
      return;
    }

    await _tryDeleteImage(oldImage);
  }

  Future<void> _tryDeleteImage(String imageUrl) async {
  try {
    await storageService.deleteCategoryImage(imageUrl);
  } catch (_) {
      // Una falla al limpiar Storage no bloquea el formulario.
  }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade100,
      colorText: AdminColors.textDark,
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }

    if (value.trim().length < 2) {
      return 'Ingresá un nombre válido';
    }

    return null;
  }

  Widget _buildImageArea(bool compact) {
    if (imageController.text.trim().isEmpty) {
      return AdminImageUploader(
        uploading: uploadingImage,
        onTap: isLoading ? null : _pickImage,
        title: 'Seleccionar imagen de categoría',
        subtitle: 'Formatos permitidos: JPG, PNG, WEBP o GIF',
      );
    }

    return Column(
      children: [
        AdminImagePreview(
          imageUrl: imageController.text.trim(),
          height: 260,
        ),
        const SizedBox(height: AdminSpacing.md),
        _buildImageActions(compact),
      ],
    );
  }

  Widget _buildImageActions(bool compact) {
    final changeButton = AdminOutlinedButton(
      text: 'Cambiar imagen',
      icon: Icons.refresh_rounded,
      expand: true,
      onPressed: isBusy ? null : _pickImage,
    );

    final removeButton = AdminOutlinedButton(
      text: 'Quitar imagen',
      icon: Icons.delete_outline_rounded,
      expand: true,
      color: Colors.redAccent,
      borderColor: Colors.redAccent.withOpacity(0.45),
      onPressed: isBusy ? null : _removeSelectedImage,
    );

    if (compact) {
      return Column(
        children: [
          changeButton,
          const SizedBox(height: AdminSpacing.sm),
          removeButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: changeButton),
        const SizedBox(width: AdminSpacing.sm),
        Expanded(child: removeButton),
      ],
    );
  }

  Widget _buildFormActions(bool compact) {
    final cancelButton = AdminOutlinedButton(
      text: 'Cancelar',
      icon: Icons.close_rounded,
      expand: compact,
      onPressed: isBusy ? null : _cancelForm,
    );

    final saveButton = AdminPrimaryButton(
      text: isEditing
          ? 'Actualizar categoría'
          : 'Crear categoría',
      icon: Icons.save_rounded,
      expand: compact,
      isLoading: isLoading,
      onPressed: uploadingImage ? null : _saveCategory,
    );

    if (compact) {
      return Column(
        children: [
          cancelButton,
          const SizedBox(height: AdminSpacing.sm),
          saveButton,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        cancelButton,
        const SizedBox(width: AdminSpacing.sm),
        saveButton,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: uploadedImageUrl == null || isClosing,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _cancelForm();
        }
      },
      child: AdminFormPage(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;

            return Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminFormHeader(
                    title: isEditing
                        ? 'Editar categoría'
                        : 'Crear nueva categoría',
                    subtitle: isEditing
                        ? 'Actualizá la información de la categoría.'
                        : 'Completá los datos para agregar una nueva categoría.',
                    onBack: isBusy ? null : _cancelForm,
                  ),

                  const SizedBox(height: AdminSpacing.lg),

                  const AdminSectionTitle(
                    title: 'Información principal',
                    subtitle:
                        'Estos datos se mostrarán en la aplicación móvil.',
                  ),

                  const SizedBox(height: AdminSpacing.md),

                  AdminTextField(
                    controller: nameController,
                    label: 'Nombre',
                    hint: 'Ejemplo: Amigurumis',
                    prefixIcon: Icons.category_outlined,
                    validator: _requiredValidator,
                  ),

                  const SizedBox(height: AdminSpacing.md),

                  AdminTextField(
                    controller: descriptionController,
                    label: 'Descripción',
                    hint:
                        'Describí brevemente qué patrones contiene esta categoría',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 5,
                  ),

                  const SizedBox(height: AdminSpacing.lg),

                  const AdminSectionTitle(
                    title: 'Imagen',
                    subtitle:
                        'Seleccioná una imagen representativa para la categoría.',
                  ),

                  const SizedBox(height: AdminSpacing.md),

                  _buildImageArea(compact),

                  const SizedBox(height: AdminSpacing.lg),

                  _buildFormActions(compact),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    imageController.dispose();
    super.dispose();
  }
}