String singularSnakeCase(String name) {
  final segments = name.split('_');
  if (segments.isEmpty) return name;

  final irregular = <String, String>{
    'data': 'data',
    'news': 'news',
    'people': 'person',
    'children': 'child',
    'men': 'man',
    'women': 'woman',
  };
  var last = segments.last;
  if (irregular.containsKey(last)) {
    last = irregular[last]!;
  } else if (last.endsWith('ies') && last.length > 3) {
    last = '${last.substring(0, last.length - 3)}y';
  } else if (last.endsWith('sses') ||
      last.endsWith('xes') ||
      last.endsWith('zes') ||
      last.endsWith('ches') ||
      last.endsWith('shes') ||
      last.endsWith('ses')) {
    last = last.substring(0, last.length - 2);
  } else if (last.endsWith('s') && !last.endsWith('ss')) {
    last = last.substring(0, last.length - 1);
  }
  segments[segments.length - 1] = last;
  return segments.join('_');
}
