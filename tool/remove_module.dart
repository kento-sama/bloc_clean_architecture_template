import 'dart:io';

import 'module_name.dart';

void main(List<String> arguments) {
  final name = arguments.isNotEmpty
      ? arguments.first
      : (Platform.environment['MODULE_NAME'] ?? '');
  final root = File.fromUri(Platform.script).parent.parent;
  try {
    removeModule(root, name);
  } on ArgumentError catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  } on FileSystemException catch (error) {
    stderr.writeln('Could not remove module: $error');
    exitCode = 1;
  } on UserCancelledException {
    stdout.writeln('Removal cancelled.');
  }
}

void removeModule(Directory root, String name, {bool confirmed = false}) {
  if (!RegExp(r'^[a-z][a-z0-9]*(?:_[a-z][a-z0-9]*)*$').hasMatch(name)) {
    throw ArgumentError(
      'Invalid module name "$name". Use lowercase snake_case, '
      'for example: dart run bin/remove_clean_module.dart watchlist_items',
    );
  }

  final separator = Platform.pathSeparator;
  final target = Directory(
    '${root.path}${separator}lib${separator}features$separator$name',
  );
  if (!target.existsSync()) {
    throw FileSystemException('Module does not exist', target.path);
  }

  if (!confirmed) {
    stdout.write('Delete ${target.path}? [y/N] ');
    final input = stdin.readLineSync();
    if (input?.trim().toLowerCase() != 'y') {
      throw UserCancelledException();
    }
  }

  target.deleteSync(recursive: true);
  _unregisterGeneratedModule(root, separator, name);
  stdout.writeln('Deleted module: lib${separator}features$separator$name');
  stdout.writeln(
    'Removed its Cubit, feature registration, and create/edit routes.',
  );
}

void _unregisterGeneratedModule(Directory root, String separator, String name) {
  final pubspec = File('${root.path}${separator}pubspec.yaml');
  final packageName = _readPackageName(pubspec);
  final words = name.split('_');
  final singular = singularSnakeCase(name);
  final singularWords = singular.split('_');
  final className = singularWords
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join();
  final variableName =
      '${words.first}${words.skip(1).map((word) => '${word[0].toUpperCase()}${word.substring(1)}').join()}';

  final appFile = File('${root.path}${separator}lib${separator}app.dart');
  var appText = appFile.readAsStringSync();
  appText = appText.replaceAll(
    "import 'package:$packageName/features/$name/presentation/cubits/${singular}_cubit.dart';",
    '',
  );
  appText = appText.replaceAll(
    "import 'package:$packageName/features/$name/data/datasources/${singular}_remote_data_source.dart';",
    '',
  );
  appText = appText.replaceAll(
    "import 'package:$packageName/features/$name/data/repositories/${singular}_repository_impl.dart';",
    '',
  );
  appText = appText.replaceAll(
    RegExp(
      '  late final ${RegExp.escape(variableName)}Cubit = '
      '${RegExp.escape(className)}Cubit\\(\\r?\\n'
      '.*?'
      '  \\);\\r?\\n',
      dotAll: true,
    ),
    '',
  );
  appText = appText.replaceAll('    ${variableName}Cubit.close();', '');
  appText = appText.replaceAll(
    '        BlocProvider.value(value: ${variableName}Cubit),',
    '',
  );
  appFile.writeAsStringSync(appText);

  final modulesFile = File(
    '${root.path}${separator}lib${separator}app_modules.dart',
  );
  var modulesText = modulesFile.readAsStringSync();
  modulesText = modulesText.replaceAll(
    "import 'package:$packageName/features/$name/${singular}_feature.dart';",
    '',
  );
  modulesText = modulesText.replaceAll('  ${variableName}Feature,\n', '');
  modulesText = modulesText.replaceAll(
    'const appModules = <AppFeature>[${variableName}Feature];',
    'const appModules = <AppFeature>[];',
  );
  modulesFile.writeAsStringSync(modulesText);

  final routerFile = File(
    '${root.path}${separator}lib${separator}core'
    '${separator}routing${separator}app_router.dart',
  );
  var routerText = routerFile.readAsStringSync();
  for (final import in [
    "import 'package:$packageName/features/$name/domain/entities/$singular.dart';",
    "import 'package:$packageName/features/$name/presentation/screens/${singular}_form_page.dart';",
    "import 'package:$packageName/features/$name/${singular}_config.dart';",
  ]) {
    routerText = routerText.replaceAll(import, '');
  }
  final escapedVariableName = RegExp.escape(variableName);
  for (final suffix in ['create', ':id/edit']) {
    final routePattern = RegExp(
      "      GoRoute\\(\\r?\\n\\s*path: '\\\$$escapedVariableName"
      'Path/$suffix.*?'
      r'      \),\r?\n',
      dotAll: true,
    );
    routerText = routerText.replaceAll(routePattern, '');
  }
  routerFile.writeAsStringSync(routerText);
}

String _readPackageName(File pubspec) {
  for (final line in pubspec.readAsLinesSync()) {
    final match = RegExp(r'^name:\s*["\x27]?([a-z][a-z0-9_]*)["\x27]?')
        .firstMatch(line);
    if (match != null) return match.group(1)!;
  }
  throw const FormatException(
    'pubspec.yaml must contain a valid package name.',
  );
}

class UserCancelledException implements Exception {}
