import 'package:flutter/material.dart';

import '../../app/design_system.dart';
import '../../app/theme.dart';

class AdminSearchField extends StatelessWidget {

  final String hint;

  final ValueChanged<String>? onChanged;

  const AdminSearchField({
    super.key,
    required this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {

    return TextField(

      onChanged: onChanged,

      decoration: InputDecoration(

        hintText: hint,

        prefixIcon: const Icon(Icons.search),

        filled: true,

        fillColor: AdminColors.background,

        border: OutlineInputBorder(

          borderRadius: BorderRadius.circular(
            AdminRadius.medium,
          ),

          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(

          borderRadius: BorderRadius.circular(
            AdminRadius.medium,
          ),

          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(

          borderRadius: BorderRadius.circular(
            AdminRadius.medium,
          ),

          borderSide: const BorderSide(
            color: AdminColors.primary,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}