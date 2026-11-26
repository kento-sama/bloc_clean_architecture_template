import 'package:material_ui/material_ui.dart';
import 'package:clean_bloc/core/presentation/app_feature.dart';
import 'package:clean_bloc/features/users/presentation/screens/user_page.dart';
import 'package:clean_bloc/features/users/user_config.dart';

// Registers this module with the app router and dashboard.
const userFeature = AppFeature(
  title: userTitle,
  path: userPath,
  viewPermission: userViewPermission,
  icon: Icons.people_outline,
  pageBuilder: _buildUserPage,
);

Widget _buildUserPage() => const UserPage();
