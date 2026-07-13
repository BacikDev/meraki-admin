import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/design_system.dart';
import '../app/theme.dart';
import '../models/admin_pattern_model.dart';
import '../services/storage_service.dart';
import '../widgets/buttons/admin_outlined_button.dart';
import '../widgets/buttons/admin_primary_button.dart';
import '../widgets/form/admin_dropdown.dart';
import '../widgets/form/form_header.dart';
import '../widgets/form/image_preview.dart';
import '../widgets/form/image_uploader.dart';
import '../widgets/form/section_title.dart';
import '../widgets/inputs/admin_text_field.dart';
import '../widgets/layout/admin_form_page.dart';

class PatternFormScreen extends StatefulWidget {
  final AdminPatternModel? pattern;

  const PatternFormScreen({
    super.key,
    this.pattern,
  });

  @override
  State<PatternFormScreen> createState() =>
      _PatternFormScreenState();
}

class _PatternFormScreenState
    extends State<PatternFormScreen> {
  final SupabaseClient supabase =
      Supabase.instance.client;

  final StorageService storageService =
      StorageService.instance;

  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  final TextEditingController titleController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  final TextEditingController imageController =
      TextEditingController();

  final TextEditingController urlController =
      TextEditingController();

  final TextEditingController orderController =
      TextEditingController(text: '0');

  bool isLoading = false;
  bool isLoadingCategories = true;
  bool uploadingImage = false;
  bool isClosing = false;

  bool isPublished = true;
  bool isFeatured = false;

  String selectedLevel = 'Fácil';
  String selectedSource = 'youtube';
  int? selectedCategoryId;

  List<Map<String, dynamic>> categories = [];

  String? originalImageUrl;
  String? uploadedImageUrl;

  bool get isEditing => widget.pattern != null;

  bool get isBusy => isLoading || uploadingImage;

  @override
  void initState() {
    super.initState();
    _loadPatternData();
    _loadCategories();
  }

  void _loadPatternData() {
    final pattern = widget.pattern;

    if (pattern == null) return;

    titleController.text = pattern.titulo;
    descriptionController.text = pattern.descripcion;
    imageController.text = pattern.imagen;
    urlController.text = pattern.url;
    orderController.text = pattern.orden.toString();

    originalImageUrl = pattern.imagen;

    selectedLevel = pattern.nivel.trim().isEmpty
        ? 'Fácil'
        : pattern.nivel.trim();

    selectedSource = pattern.fuente.trim().isEmpty
        ? 'youtube'
        : pattern.fuente.trim().toLowerCase();

    const availableSources = {
      'youtube',
      'instagram',
      'tiktok',
    };

    if (!availableSources.contains(selectedSource)) {
      selectedSource = 'youtube';
    }

    selectedCategoryId = pattern.categoriaId;
    isPublished = pattern.publicado;
    isFeatured = pattern.destacado;
  }

  Future<void> _loadCategories() async {
    try {
      if (mounted) {
        setState(() {
          isLoadingCategories = true;
        });
      }

      final response = await supabase
          .from('categories')
          .select('id, nombre')
          .order(
            'nombre',
            ascending: true,
          );

      if (!mounted) return;

      final loadedCategories =
          List<Map<String, dynamic>>.from(response);

      setState(() {
        categories = loadedCategories;

        final categoryExists =
            selectedCategoryId != null &&
                categories.any(
                  (category) =>
                      category['id'] ==
                      selectedCategoryId,
                );

        if (!categoryExists &&
            categories.isNotEmpty) {
          selectedCategoryId =
              categories.first['id'] as int;
        }
      });
    } catch (error) {
      _showError(
        'No se pudieron cargar las categorías',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    if (isBusy) return;

    try {
      setState(() {
        uploadingImage = true;
      });

      final newImageUrl =
          await storageService
              .pickAndUploadPatternImage();

      if (newImageUrl == null || !mounted) return;

      final previousTemporaryImage =
          uploadedImageUrl;

      if (previousTemporaryImage != null &&
          previousTemporaryImage != newImageUrl) {
        await _tryDeleteImage(
          previousTemporaryImage,
        );
      }

      setState(() {
        uploadedImageUrl = newImageUrl;
        imageController.text = newImageUrl;
      });

      Get.snackbar(
        'Imagen subida',
        'La imagen se cargó correctamente',
        backgroundColor:
            AdminColors.primaryLight,
        colorText: AdminColors.textDark,
      );
    } catch (_) {
      _showError(
        'No se pudo subir la imagen',
      );
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

  Future<void> _savePattern() async {
    FocusScope.of(context).unfocus();

    if (!(formKey.currentState?.validate() ??
        false)) {
      return;
    }

    if (selectedCategoryId == null) {
      Get.snackbar(
        'Categoría requerida',
        'Seleccioná una categoría para el patrón',
        backgroundColor:
            AdminColors.primaryLight,
        colorText: AdminColors.textDark,
      );
      return;
    }

    if (imageController.text.trim().isEmpty) {
      Get.snackbar(
        'Imagen requerida',
        'Seleccioná una imagen para el patrón',
        backgroundColor:
            AdminColors.primaryLight,
        colorText: AdminColors.textDark,
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final data = <String, dynamic>{
        'titulo': titleController.text.trim(),
        'descripcion':
            descriptionController.text.trim(),
        'imagen': imageController.text.trim(),
        'categoria_id': selectedCategoryId,
        'nivel': selectedLevel,
        'fuente': selectedSource,
        'url': urlController.text.trim(),
        'publicado': isPublished,
        'destacado': isFeatured,
        'orden': int.tryParse(
              orderController.text.trim(),
            ) ??
            0,
      };

      if (isEditing) {
        await supabase
            .from('patterns')
            .update(data)
            .eq('id', widget.pattern!.id);

        await _deletePreviousImageAfterUpdate();

        Get.snackbar(
          'Patrón actualizado',
          'Los cambios fueron guardados correctamente',
          backgroundColor:
              AdminColors.primaryLight,
          colorText: AdminColors.textDark,
        );
      } else {
        await supabase
            .from('patterns')
            .insert(data);

        Get.snackbar(
          'Patrón creado',
          isPublished
              ? 'El patrón ya está disponible en la aplicación'
              : 'El patrón fue guardado como no publicado',
          backgroundColor:
              AdminColors.primaryLight,
          colorText: AdminColors.textDark,
        );
      }

      uploadedImageUrl = null;
      isClosing = true;

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      _showError(
        'No se pudo guardar el patrón',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void>
      _deletePreviousImageAfterUpdate() async {
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

  Future<void> _tryDeleteImage(
    String imageUrl,
  ) async {
    try {
      await storageService.deletePatternImage(
        imageUrl,
      );
    } catch (_) {
      // La limpieza no bloquea el guardado.
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

    return null;
  }

  String? _urlValidator(String? value) {
    final requiredError =
        _requiredValidator(value);

    if (requiredError != null) {
      return requiredError;
    }

    final uri = Uri.tryParse(value!.trim());

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        !{'http', 'https'}
            .contains(uri.scheme.toLowerCase())) {
      return 'Ingresá una URL válida';
    }

    return null;
  }

  String? _orderValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresá un número de orden';
    }

    final parsed = int.tryParse(value.trim());

    if (parsed == null) {
      return 'El orden debe ser un número entero';
    }

    if (parsed < 0) {
      return 'El orden no puede ser negativo';
    }

    return null;
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

  Widget _buildCategoryField() {
    if (isLoadingCategories) {
      return Container(
        height: AdminSizes.inputHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.md,
        ),
        decoration: AdminDecorations.input,
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AdminColors.primary,
              ),
            ),
            SizedBox(width: AdminSpacing.sm),
            Text('Cargando categorías...'),
          ],
        ),
      );
    }

    if (categories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          AdminSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(
            AdminRadius.medium,
          ),
          border: Border.all(
            color: Colors.orange.withOpacity(0.25),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
            SizedBox(width: AdminSpacing.sm),
            Expanded(
              child: Text(
                'No hay categorías disponibles. Creá una categoría antes de guardar el patrón.',
              ),
            ),
          ],
        ),
      );
    }

    final categoryIds = categories
        .map<int>(
          (category) => category['id'] as int,
        )
        .toList();

    return AdminDropdown<int>(
      label: 'Categoría',
      value: selectedCategoryId,
      items: categoryIds,
      itemLabel: (id) {
        final category = categories.firstWhere(
          (item) => item['id'] == id,
          orElse: () => {
            'nombre': 'Sin categoría',
          },
        );

        return category['nombre']?.toString() ??
            'Sin categoría';
      },
      onChanged: isBusy
          ? (_) {}
          : (value) {
              setState(() {
                selectedCategoryId = value;
              });
            },
    );
  }

  Widget _buildClassificationFields(
    bool compact,
  ) {
    final levelField = AdminDropdown<String>(
      label: 'Nivel',
      value: selectedLevel,
      items: const [
        'Fácil',
        'Medio',
        'Avanzado',
      ],
      itemLabel: (value) => value,
      onChanged: isBusy
          ? (_) {}
          : (value) {
              if (value == null) return;

              setState(() {
                selectedLevel = value;
              });
            },
    );

    final sourceField =
        AdminDropdown<String>(
      label: 'Fuente',
      value: selectedSource,
      items: const [
        'youtube',
        'instagram',
        'tiktok',
      ],
      itemLabel: _sourceLabel,
      onChanged: isBusy
          ? (_) {}
          : (value) {
              if (value == null) return;

              setState(() {
                selectedSource = value;
              });
            },
    );

    if (compact) {
      return Column(
        children: [
          levelField,
          const SizedBox(
            height: AdminSpacing.md,
          ),
          sourceField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: levelField),
        const SizedBox(
          width: AdminSpacing.md,
        ),
        Expanded(child: sourceField),
      ],
    );
  }

  Widget _buildImageArea(bool compact) {
    if (imageController.text.trim().isEmpty) {
      return AdminImageUploader(
        uploading: uploadingImage,
        onTap: isLoading ? null : _pickImage,
      );
    }

    return Column(
      children: [
        AdminImagePreview(
          imageUrl:
              imageController.text.trim(),
        ),
        const SizedBox(
          height: AdminSpacing.md,
        ),
        _buildImageActions(compact),
      ],
    );
  }

  Widget _buildImageActions(bool compact) {
    final changeButton =
        AdminOutlinedButton(
      text: 'Cambiar imagen',
      icon: Icons.refresh_rounded,
      expand: true,
      onPressed: isBusy ? null : _pickImage,
    );

    final removeButton =
        AdminOutlinedButton(
      text: 'Quitar imagen',
      icon: Icons.delete_outline_rounded,
      expand: true,
      color: Colors.redAccent,
      borderColor:
          Colors.redAccent.withOpacity(0.45),
      onPressed:
          isBusy ? null : _removeSelectedImage,
    );

    if (compact) {
      return Column(
        children: [
          changeButton,
          const SizedBox(
            height: AdminSpacing.sm,
          ),
          removeButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: changeButton),
        const SizedBox(
          width: AdminSpacing.sm,
        ),
        Expanded(child: removeButton),
      ],
    );
  }

  Widget _buildPublicationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        AdminSpacing.md,
      ),
      decoration: AdminDecorations.input,
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Publicado'),
            subtitle: const Text(
              'El patrón será visible en la aplicación.',
            ),
            value: isPublished,
            activeColor: AdminColors.primary,
            onChanged: isBusy
                ? null
                : (value) {
                    setState(() {
                      isPublished = value;

                      if (!value) {
                        isFeatured = false;
                      }
                    });
                  },
          ),
          const Divider(
            color: AdminBorders.soft,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Destacado'),
            subtitle: Text(
              isPublished
                  ? 'Aparecerá en la sección de destacados.'
                  : 'Primero debés publicar el patrón.',
            ),
            value: isFeatured,
            activeColor: AdminColors.primary,
            onChanged: isBusy || !isPublished
                ? null
                : (value) {
                    setState(() {
                      isFeatured = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildFormActions(bool compact) {
    final cancelButton =
        AdminOutlinedButton(
      text: 'Cancelar',
      icon: Icons.close_rounded,
      expand: compact,
      onPressed: isBusy ? null : _cancelForm,
    );

    final saveButton = AdminPrimaryButton(
      text: isEditing
          ? 'Actualizar patrón'
          : 'Crear patrón',
      icon: Icons.save_rounded,
      expand: compact,
      isLoading: isLoading,
      onPressed:
          uploadingImage ? null : _savePattern,
    );

    if (compact) {
      return Column(
        children: [
          cancelButton,
          const SizedBox(
            height: AdminSpacing.sm,
          ),
          saveButton,
        ],
      );
    }

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.end,
      children: [
        cancelButton,
        const SizedBox(
          width: AdminSpacing.sm,
        ),
        saveButton,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          uploadedImageUrl == null || isClosing,
      onPopInvokedWithResult:
          (didPop, result) async {
        if (!didPop) {
          await _cancelForm();
        }
      },
      child: AdminFormPage(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 760;

            return Form(
              key: formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  AdminFormHeader(
                    title: isEditing
                        ? 'Editar patrón'
                        : 'Crear nuevo patrón',
                    subtitle: isEditing
                        ? 'Actualizá la información publicada en Meraki.'
                        : 'Completá los datos para publicar un nuevo patrón.',
                    onBack:
                        isBusy ? null : _cancelForm,
                  ),

                  const SizedBox(
                    height: AdminSpacing.lg,
                  ),

                  const AdminSectionTitle(
                    title:
                        'Información principal',
                    subtitle:
                        'Datos que se mostrarán en la aplicación móvil.',
                  ),

                  const SizedBox(
                    height: AdminSpacing.md,
                  ),

                  AdminTextField(
                    controller: titleController,
                    label: 'Título',
                    hint:
                        'Ejemplo: Conejo amigurumi',
                    prefixIcon:
                        Icons.title_rounded,
                    validator:
                        _requiredValidator,
                  ),

                  const SizedBox(
                    height: AdminSpacing.md,
                  ),

                  AdminTextField(
                    controller:
                        descriptionController,
                    label: 'Descripción',
                    hint:
                        'Explicá brevemente de qué trata este patrón',
                    prefixIcon:
                        Icons.description_outlined,
                    maxLines: 5,
                  ),

                  const SizedBox(
                    height: AdminSpacing.lg,
                  ),

                  const AdminSectionTitle(
                    title: 'Clasificación',
                    subtitle:
                        'Definí la categoría, dificultad y plataforma de origen.',
                  ),

                  const SizedBox(
                    height: AdminSpacing.md,
                  ),

                  _buildClassificationFields(
                    compact,
                  ),

                  const SizedBox(
                    height: AdminSpacing.md,
                  ),

                  _buildCategoryField(),

                  const SizedBox(
                    height: AdminSpacing.lg,
                  ),

                  const AdminSectionTitle(
                    title: 'Contenido externo',
                    subtitle:
                        'Seleccioná una imagen y agregá el enlace original del patrón.',
                  ),

                  const SizedBox(
                    height: AdminSpacing.md,
                  ),

                  _buildImageArea(compact),

                  const SizedBox(
                    height: AdminSpacing.md,
                  ),

                  AdminTextField(
                    controller: urlController,
                    label: 'URL del patrón',
                    hint:
                        'https://youtube.com/...',
                    prefixIcon:
                        Icons.link_rounded,
                    keyboardType:
                        TextInputType.url,
                    validator: _urlValidator,
                  ),

                  const SizedBox(
                    height: AdminSpacing.lg,
                  ),

                  const AdminSectionTitle(
                    title: 'Publicación',
                    subtitle:
                        'Controlá la visibilidad, destacados y el orden del patrón.',
                  ),

                  const SizedBox(
                    height: AdminSpacing.md,
                  ),

                  _buildPublicationSection(),

                  const SizedBox(
                    height: AdminSpacing.md,
                  ),

                  AdminTextField(
                    controller: orderController,
                    label: 'Orden',
                    hint: '0',
                    prefixIcon:
                        Icons.sort_rounded,
                    keyboardType:
                        TextInputType.number,
                    validator: _orderValidator,
                  ),

                  const SizedBox(
                    height: AdminSpacing.lg,
                  ),

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
    titleController.dispose();
    descriptionController.dispose();
    imageController.dispose();
    urlController.dispose();
    orderController.dispose();
    super.dispose();
  }
}