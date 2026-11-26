import 'package:material_ui/material_ui.dart';

/// Describes a module's navigation and the permission needed to open it.
class AppFeature {
  const AppFeature({
    required this.title,
    required this.path,
    required this.viewPermission,
    required this.icon,
    required this.pageBuilder,
  });

  final String title;
  final String path;
  final String viewPermission;
  final IconData icon;
  final Widget Function() pageBuilder;
}
