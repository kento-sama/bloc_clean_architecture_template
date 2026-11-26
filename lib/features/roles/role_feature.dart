import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/app_feature.dart';
import 'package:clean_bloc/features/roles/presentation/screens/role_page.dart';
import 'package:clean_bloc/features/roles/role_config.dart';

// Registers this module with the app router and dashboard.
const roleFeature = AppFeature(
  title: roleTitle,
  path: rolePath,
  viewPermission: roleViewPermission,
  icon: Icons.badge_outlined,
  pageBuilder: _buildRolePage,
);

Widget _buildRolePage() => const RolePage();
