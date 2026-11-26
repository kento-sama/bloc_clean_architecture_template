import 'dart:io';

void main(List<String> arguments) {
  final name = arguments.isNotEmpty
      ? arguments.first
      : (Platform.environment['MODULE_NAME'] ?? '');
  final root = File.fromUri(Platform.script).parent.parent;
  try {
    scaffoldModule(root, name);
    final targetPath =
        '${root.path}${Platform.pathSeparator}lib'
        '${Platform.pathSeparator}features${Platform.pathSeparator}$name';
    final format = Process.runSync(Platform.resolvedExecutable, [
      'format',
      targetPath,
    ]);
    if (format.exitCode != 0) {
      stderr.writeln('Could not format generated module:');
      stderr.write(format.stdout);
      stderr.write(format.stderr);
      exitCode = format.exitCode;
      return;
    }
    final words = name.split('_');
    final className = words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join();
    final variableName =
        '${words.first}${className.substring(words.first.length)}';
    stdout.writeln(
      'Created module: lib${Platform.pathSeparator}features'
      '${Platform.pathSeparator}$name',
    );
    stdout.writeln(
      'Registered ${variableName}Cubit, ${variableName}Feature, and '
      'create/edit routes. Adapt the API, fields, and permissions '
      'for your backend.',
    );
  } on ArgumentError catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  } on FileSystemException catch (error) {
    stderr.writeln('Could not generate module: $error');
    stderr.writeln(
      'Check lib/features/$name for any partially generated files.',
    );
    exitCode = 1;
  }
}

void scaffoldModule(Directory root, String name) {
  if (!RegExp(r'^[a-z][a-z0-9]*(?:_[a-z][a-z0-9]*)*$').hasMatch(name)) {
    throw ArgumentError(
      'Invalid module name "$name". Use lowercase snake_case, '
      'for example: dart run bin/clean_module.dart watchlist_items',
    );
  }

  final separator = Platform.pathSeparator;
  final target = Directory(
    '${root.path}${separator}lib${separator}features'
    '$separator$name',
  );
  if (FileSystemEntity.typeSync(target.path, followLinks: false) !=
      FileSystemEntityType.notFound) {
    throw FileSystemException('Module already exists', target.path);
  }

  final words = name.split('_');
  final className = words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join();
  final variableName =
      '${words.first}${className.substring(words.first.length)}';
  final title = words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
  final pubspec = File('${root.path}${separator}pubspec.yaml');
  final packageName = _readPackageName(pubspec);
  final replacements = {
    '__snake__': name,
    '__camel__': variableName,
    '__pascal__': className,
    '__title__': title,
    '__package__': packageName,
  };
  final templates = <String, String>{
    'config.dart.tmpl': '${name}_config.dart',
    'feature.dart.tmpl': '${name}_feature.dart',
    'entity.dart.tmpl':
        'domain$separator'
        'entities$separator$name.dart',
    'repository.dart.tmpl':
        'domain$separator'
        'repositories$separator${name}_repository.dart',
    'use_cases.dart.tmpl':
        'domain$separator'
        'usecases$separator${name}_use_cases.dart',
    'model.dart.tmpl':
        'data$separator'
        'models$separator${name}_model.dart',
    'api.dart.tmpl':
        'data$separator'
        'datasources$separator${name}_remote_data_source.dart',
    'repository_impl.dart.tmpl':
        'data$separator'
        'repositories$separator${name}_repository_impl.dart',
    'cubit.dart.tmpl':
        'presentation$separator'
        'cubits$separator${name}_cubit.dart',
    'page.dart.tmpl':
        'presentation$separator'
        'screens$separator${name}_page.dart',
    'form_page.dart.tmpl':
        'presentation$separator'
        'screens$separator${name}_form_page.dart',
    'actions_widget.dart.tmpl':
        'presentation$separator'
        'widgets$separator${name}_actions.dart',
  };

  final rendered = <String, String>{};
  for (final entry in templates.entries) {
    final template = File(
      '${root.path}${separator}tool${separator}module_templates'
      '$separator${entry.key}',
    ).readAsStringSync();
    var content = template;
    for (final replacement in replacements.entries) {
      content = content.replaceAll(replacement.key, replacement.value);
    }
    rendered[entry.value] = content;
  }

  target.createSync();
  for (final entry in rendered.entries) {
    final file = File('${target.path}$separator${entry.key}');
    file.parent.createSync(recursive: true);
    file.createSync(exclusive: true);
    file.writeAsStringSync(entry.value);
  }

  _registerGeneratedModule(
    root,
    separator,
    packageName,
    name,
    className,
    variableName,
  );

  final folders = <String>[
    'domain',
    'domain${separator}entities',
    'domain${separator}repositories',
    'domain${separator}usecases',
    'data',
    'data${separator}models',
    'data${separator}datasources',
    'data${separator}repositories',
    'presentation',
    'presentation${separator}cubits',
    'presentation${separator}screens',
    'presentation${separator}widgets',
  ];
  for (final folder in folders) {
    final directory = Directory('${target.path}$separator$folder');
    directory.createSync(recursive: true);
    final gitkeep = File('${directory.path}$separator.gitkeep');
    if (!gitkeep.existsSync()) {
      gitkeep.createSync();
    }
  }
}

void _registerGeneratedModule(
  Directory root,
  String separator,
  String packageName,
  String name,
  String className,
  String variableName,
) {
  _patchAppRoot(root, packageName, name, className, variableName);
  _patchAppModules(root, packageName, name, variableName);
  _patchAppRouter(root, packageName, name, className, variableName);
}

void _patchAppRoot(
  Directory root,
  String packageName,
  String name,
  String className,
  String variableName,
) {
  final file = File(
    '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}app.dart',
  );
  var text = file.readAsStringSync();
  final imports = [
    "import 'package:$packageName/features/$name/presentation/cubits/${name}_cubit.dart';",
    "import 'package:$packageName/features/$name/data/datasources/${name}_remote_data_source.dart';",
    "import 'package:$packageName/features/$name/data/repositories/${name}_repository_impl.dart';",
  ].join('\n');
  text = _insertAfterUnique(
    text,
    "import 'package:$packageName/features/permissions/presentation/cubits/permission_cubit.dart';",
    '\n$imports',
  );
  text = _insertBeforeUnique(
    text,
    '  late final router = createAppRouter(authCubit);',
    '  late final ${variableName}Cubit = ${className}Cubit(\n'
        '    ${className}RepositoryImpl(\n'
        '      ${className}RemoteDataSource(dependencies.dio),\n'
        '    ),\n'
        '  );\n',
  );
  text = text.replaceFirst(
    '  late final router = createAppRouter(authCubit);',
    '  late final router = createAppRouter(authCubit);',
  );
  text = text.replaceFirst(
    '    permissionCubit.close();',
    '    permissionCubit.close();\n'
        '    ${variableName}Cubit.close();',
  );
  text = text.replaceFirst(
    '        BlocProvider.value(value: permissionCubit),',
    '        BlocProvider.value(value: permissionCubit),\n'
        '        BlocProvider.value(value: ${variableName}Cubit),',
  );
  file.writeAsStringSync(text);
}

void _patchAppModules(
  Directory root,
  String packageName,
  String name,
  String variableName,
) {
  final file = File(
    '${root.path}${Platform.pathSeparator}lib${Platform.pathSeparator}app_modules.dart',
  );
  var text = file.readAsStringSync();
  text = _insertAfterUnique(
    text,
    "import 'package:$packageName/features/users/user_feature.dart';",
    "\nimport 'package:$packageName/features/$name/${name}_feature.dart';",
  );
  text = text.replaceFirst(
    'const appModules = <AppFeature>[userFeature, roleFeature, permissionFeature];',
    'const appModules = <AppFeature>[\n'
        '  userFeature,\n'
        '  roleFeature,\n'
        '  permissionFeature,\n'
        '  ${variableName}Feature,\n'
        '];',
  );
  file.writeAsStringSync(text);
}

void _patchAppRouter(
  Directory root,
  String packageName,
  String name,
  String className,
  String variableName,
) {
  final file = File(
    '${root.path}${Platform.pathSeparator}lib'
    '${Platform.pathSeparator}core'
    '${Platform.pathSeparator}routing'
    '${Platform.pathSeparator}app_router.dart',
  );
  var text = file.readAsStringSync();
  final imports = [
    "import 'package:$packageName/features/$name/domain/entities/$name.dart';",
    "import 'package:$packageName/features/$name/presentation/screens/${name}_form_page.dart';",
    "import 'package:$packageName/features/$name/${name}_config.dart';",
  ].join('\n');
  text = _insertAfterUnique(
    text,
    "import 'package:$packageName/features/permissions/permission_config.dart';",
    '\n$imports',
  );
  final routes =
      '''
      GoRoute(
        path: '\$${variableName}Path/create',
        redirect: (_, _) =>
            authCubit.state.value?.canAccess(${variableName}CreatePermission) == true
            ? null
            : '/forbidden',
        builder: (_, _) => const ${className}FormPage(),
      ),
      GoRoute(
        path: '\$${variableName}Path/:id/edit',
        redirect: (_, state) {
          if (state.extra is! ${className}Entity) return ${variableName}Path;
          return authCubit.state.value?.canAccess(${variableName}UpdatePermission) == true
              ? null
              : '/forbidden';
        },
        builder: (_, state) => ${className}FormPage(
          item: state.extra is ${className}Entity
              ? state.extra as ${className}Entity
              : null,
        ),
      ),''';
  text = text.replaceFirst(
    "      GoRoute(path: '/forbidden'",
    '$routes\n'
        "      GoRoute(path: '/forbidden'",
  );
  file.writeAsStringSync(text);
}

String _insertAfterUnique(String text, String anchor, String insertion) {
  if (!text.contains(anchor)) {
    throw StateError(
      'Could not update generated module. Missing anchor: $anchor',
    );
  }
  return text.replaceFirst(anchor, '$anchor$insertion');
}

String _insertBeforeUnique(String text, String anchor, String insertion) {
  if (!text.contains(anchor)) {
    throw StateError(
      'Could not update generated module. Missing anchor: $anchor',
    );
  }
  return text.replaceFirst(anchor, '$insertion$anchor');
}

String _readPackageName(File pubspec) {
  if (!pubspec.existsSync()) {
    throw FileSystemException('pubspec.yaml was not found', pubspec.path);
  }
  for (final line in pubspec.readAsLinesSync()) {
    final match = RegExp(r'^name:\s*([a-z][a-z0-9_]*)').firstMatch(line);
    if (match != null) return match.group(1)!;
  }
  throw const FormatException(
    'pubspec.yaml must contain a valid package name.',
  );
}
