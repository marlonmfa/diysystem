import 'dart:convert';

String canonicalize(Object? value) {
  if (value is List) {
    return '[${value.map(canonicalize).join(',')}]';
  }
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return '{${keys.map((key) => '${jsonEncode(key)}:${canonicalize(value[key])}').join(',')}}';
  }
  return jsonEncode(value);
}
