import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/app_feature.dart';
import 'package:clean_bloc/features/permissions/permission_config.dart';
import 'package:clean_bloc/features/permissions/presentation/screens/permission_page.dart';

// Registers this module with the app router and dashboard.
const permissionFeature = AppFeature(
  title: permissionTitle,
  path: permissionPath,
  viewPermission: permissionViewPermission,
  icon: Icons.key_outlined,
  pageBuilder: _buildPermissionPage,
);

Widget _buildPermissionPage() => const PermissionPage();
