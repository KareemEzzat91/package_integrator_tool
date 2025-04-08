import 'dart:io';
import 'package:yaml/yaml.dart';
class YamlEditor {
  final String _source;
  late final YamlMap _yaml;

  YamlEditor(this._source) {
    _yaml = loadYaml(_source) as YamlMap;
  }

  /// Add a dependency to the pubspec.yaml
  String addDependency(String name, String version) {


    String result = _source;
    if (_yaml['dependencies'] != null && _yaml['dependencies'][name] != null) {
      final pattern = RegExp('$name:.*\\n');
      result = result.replaceFirst(pattern, '$name: ^$version\n');
    } else {
      final dependenciesIndex = result.indexOf('dependencies:');
      if (dependenciesIndex == -1) {
        throw Exception('Could not find dependencies section');
      }

      final nextLineIndex = result.indexOf('\n', dependenciesIndex);
      if (nextLineIndex == -1) {
        throw Exception('Invalid YAML format');
      }

      result = '${result.substring(0, nextLineIndex + 1)}  $name: ^$version\n${result.substring(nextLineIndex + 1)}';
    }

    return result;
  }
  static Future<void> writeToFile(File file, String content) async {
    await file.writeAsString(content);
  }
}