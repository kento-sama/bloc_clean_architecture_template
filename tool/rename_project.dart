import 'dart:io';

void main(List<String> arguments) {
  final name = arguments.isNotEmpty
      ? arguments.first
      : (Platform.environment['PROJECT_NAME'] ?? '');
  final root = File.fromUri(Platform.script).parent.parent;

  try {
    renameProject(root, name);
  } on ArgumentError catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  } on FileSystemException catch (error) {
    stderr.writeln('Could not rename project: $error');
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  }
}

void renameProject(Directory root, String name) {
  if (!RegExp(r'^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$').hasMatch(name)) {
    throw ArgumentError(
      'Invalid project name "$name". Use lowercase snake_case, '
      'for example: dart run bin/rename_project.dart inventory_app',
    );
  }

  final separator = Platform.pathSeparator;
  final pubspec = File('${root.path}${separator}pubspec.yaml');
  if (!pubspec.existsSync()) {
    throw FileSystemException('pubspec.yaml was not found', pubspec.path);
  }

  final oldName = _readPackageName(pubspec);
  if (oldName == name) {
    stdout.writeln('Project package name is already "$name".');
    return;
  }

  var pubspecText = pubspec.readAsStringSync();
  pubspecText = pubspecText.replaceFirst(
    RegExp(r'^name:\s*[^\s]+', multiLine: true),
    'name: $name',
  );
  pubspec.writeAsStringSync(pubspecText);

  for (final directoryName in const ['lib', 'test', 'tool', 'bin']) {
    final directory = Directory('${root.path}$separator$directoryName');
    if (!directory.existsSync()) continue;
    for (final file
        in directory
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      final text = file.readAsStringSync();
      if (text.contains('package:$oldName/')) {
        file.writeAsStringSync(
          text.replaceAll('package:$oldName/', 'package:$name/'),
        );
      }
    }
  }

  final oldTitle = _readWebTitle(root);
  final newTitle = name
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  if (oldTitle.isNotEmpty) {
    _replaceInTextFiles(
      root,
      oldTitle,
      newTitle,
      const ['lib', 'web'],
      const {'.dart', '.html', '.json'},
    );
  }

  _renameIdeMetadata(root, oldName, name);

  stdout.writeln('Renamed project package: $oldName -> $name');
  stdout.writeln(
    'Updated Dart package imports, web project title, and IntelliJ metadata.',
  );
}

void _renameIdeMetadata(Directory root, String oldName, String newName) {
  final separator = Platform.pathSeparator;
  final entries = root.listSync(followLinks: false);

  for (final entity in entries) {
    if (entity is! File || !entity.path.endsWith('.iml')) continue;
    var text = entity.readAsStringSync();
    if (text.contains(oldName)) {
      entity.writeAsStringSync(text.replaceAll(oldName, newName));
    }

    final oldFileName = entity.uri.pathSegments.last;
    final oldBaseName = oldFileName.substring(0, oldFileName.length - 4);
    String? newBaseName;
    if (oldBaseName == oldName) {
      newBaseName = newName;
    } else if (oldBaseName ==
        '$oldName'
            '_android') {
      newBaseName =
          '$newName'
          '_android';
    }

    if (newBaseName != null) {
      entity.renameSync('${root.path}$separator$newBaseName.iml');
    }
  }

  final ideaDirectory = Directory('${root.path}$separator.idea');
  if (!ideaDirectory.existsSync()) return;
  for (final entity in ideaDirectory.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.xml') && !entity.path.endsWith('.iml')) {
      continue;
    }
    var text = entity.readAsStringSync();
    if (text.contains(oldName)) {
      entity.writeAsStringSync(text.replaceAll(oldName, newName));
    }
  }
}

String _readPackageName(File pubspec) {
  for (final line in pubspec.readAsLinesSync()) {
    final match = RegExp(r'^name:\s*([a-z][a-z0-9_]*)').firstMatch(line);
    if (match != null) return match.group(1)!;
  }
  throw const FormatException(
    'pubspec.yaml must contain a valid package name.',
  );
}

String _readWebTitle(Directory root) {
  final manifest = File(
    '${root.path}${Platform.pathSeparator}web'
    '${Platform.pathSeparator}manifest.json',
  );
  if (!manifest.existsSync()) return '';
  String line = '';
  for (final candidate in manifest.readAsLinesSync()) {
    if (candidate.contains('"name"')) {
      line = candidate;
      break;
    }
  }
  final match = RegExp(r'"name"\s*:\s*"([^"]*)"').firstMatch(line);
  return match?.group(1) ?? '';
}

void _replaceInTextFiles(
  Directory root,
  String oldText,
  String newText,
  List<String> directories,
  Set<String> extensions,
) {
  final separator = Platform.pathSeparator;
  for (final directoryName in directories) {
    final directory = Directory('${root.path}$separator$directoryName');
    if (!directory.existsSync()) continue;
    for (final file
        in directory
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((file) => extensions.any(file.path.endsWith))) {
      final text = file.readAsStringSync();
      if (text.contains(oldText)) {
        file.writeAsStringSync(text.replaceAll(oldText, newText));
      }
    }
  }
}
