import 'dart:io';

class PubspecInfo {
  // const PubspecInfo({String? path})
  //     : _file = File(path ?? '${Directory.current.path}/pubspec.yaml');

  PubspecInfo({this.path});

  final String? path;
  File get _file {
    final finalPath = path ?? '${Directory.current.path}/pubspec.yaml';
    final file = File(finalPath);
    if (file.existsSync()) return file;
    throw 'Pubspec file not exists. Path: $finalPath';
  }

  List<String> get _lines => _file.readAsLinesSync();

  static const String _versionKey = 'version:';

  String get version {
    final versionLine = _lines[_getIdxLineWhereContains(_versionKey)];
    return versionLine.replaceAll(_versionKey, '').trim();
  }

  set version(String version) {
    final versionIdxLine = _getIdxLineWhereContains(_versionKey);
    final newPubInfo = [..._lines];
    newPubInfo[versionIdxLine] = '$_versionKey $version';
    _file.writeAsStringSync(newPubInfo.join('\n'));
  }

  int _getIdxLineWhereContains(String text) {
    final pubStringLines = _file.readAsLinesSync();
    return pubStringLines.indexWhere((e) => e.contains(text));
  }
}
