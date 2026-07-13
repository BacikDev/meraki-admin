import 'package:flutter/material.dart';

import '../../app/design_system.dart';
import '../../app/theme.dart';
import '../buttons/admin_primary_button.dart';
import '../inputs/admin_search_field.dart';

class AdminCrudScreen extends StatelessWidget {
  final String title;
  final String subtitle;

  final String searchHint;

  final ValueChanged<String>? onSearch;

  final String addButtonText;

  final VoidCallback? onAdd;

  final Widget child;

  final bool showSearch;

  final bool showAddButton;

  const AdminCrudScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.searchHint = 'Buscar...',
    this.onSearch,
    this.addButtonText = 'Nuevo',
    this.onAdd,
    this.showSearch = true,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final compact = width < 800;

    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: AdminTextStyles.pageTitle,
          ),

          const SizedBox(height: 6),

          Text(
            subtitle,
            style: AdminTextStyles.pageSubtitle,
          ),

          const SizedBox(height: 30),

          if (compact)
            Column(
              children: [

                if (showSearch)
                  AdminSearchField(
                    hint: searchHint,
                    onChanged: onSearch,
                  ),

                if (showSearch)
                  const SizedBox(height: 16),

                if (showAddButton)
                  SizedBox(
                    width: double.infinity,
                    child: AdminPrimaryButton(
                      text: addButtonText,
                      icon: Icons.add,
                      expand: true,
                      onPressed: onAdd,
                    ),
                  ),
              ],
            )
          else
            Row(
              children: [

                if (showSearch)
                  Expanded(
                    child: AdminSearchField(
                      hint: searchHint,
                      onChanged: onSearch,
                    ),
                  ),

                if (showSearch && showAddButton)
                  const SizedBox(width: 20),

                if (showAddButton)
                  AdminPrimaryButton(
                    text: addButtonText,
                    icon: Icons.add,
                    onPressed: onAdd,
                  ),
              ],
            ),

          const SizedBox(height: 25),

          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}