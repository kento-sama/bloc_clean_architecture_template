import 'package:clean_bloc/core/presentation/app_feature.dart';
import 'package:clean_bloc/features/permissions/permission_feature.dart';
import 'package:clean_bloc/features/roles/role_feature.dart';
import 'package:clean_bloc/features/users/user_feature.dart';

/// Composition root for optional application features.
///
/// Adding, removing, or replacing a feature belongs here; feature-specific
/// behavior remains inside that feature.
const appModules = <AppFeature>[userFeature, roleFeature, permissionFeature];
