import 'dart:io';

import 'package:process_run/shell.dart';

import '../tag_to_deploy_creator.dart';
import 'pubspec_info.dart';
import 'version.dart';

class TagToDeployCreatorBase implements TagToDeployCreator {
  TagToDeployCreatorBase({
    required this.shell,
    required this.pubspecInfo,
  });

  final Shell shell;
  final PubspecInfo pubspecInfo;

  late final Version _versionPubspec;
  Target? _target;
  Version? _versionRecommended;
  Version? _versionFromUser;
  String? _commitMessage;

  @override
  Future<void> create() async {
    try {
      await _getTarget();
      await _checkBranchName();
      _getVersionFromPubspec();
      await _getVersionRecommended();
      _getVersionFromUser();
      await _commitVersion();
      _setPubspecVersionFromUser();
      await _createTag();
      stdout.writeln('TagToDeployCreator Finished!');
    } catch (e) {
      _setPubspecVersionToOriginal();
      stdout.writeln(e);
    }
  }

  Future<void> _getTarget() async {
    stdout.writeln('');
    stdout.writeln('Choose the target:');
    stdout.writeln('   r => "release"');
    stdout.writeln('   t => "test"');

    stdin.lineMode = false;
    stdin.echoMode = false;
    final text = String.fromCharCodes([stdin.readByteSync()]);
    stdin.lineMode = true;
    stdin.echoMode = true;
    if (text == 'r') _target = Target.release;
    if (text == 't') _target = Target.test;
    if (_target == null) return _getTarget();
  }

  Future<void> _checkBranchName() async {
    final result = await shell.run('git branch --show-current');
    final branchName = result.outText;
    switch (_target) {
      case Target.test:
        await shell.run('git push --set-upstream origin $branchName');
        return;
      case Target.release:
        if (branchName == 'master') return;
        throw ('Release deploy can only be pushed on MASTER branch');
      case null:
        throw 'target is null';
    }
  }

  void _getVersionFromPubspec() {
    try {
      final version = pubspecInfo.version;
      _versionPubspec = Version.parse(version);
    } catch (e) {
      throw 'Error on get version from pubspec.yaml\n$e';
    }
  }

  Future<void> _getVersionRecommended() async {
    var build = await _getMajorBuildFromPublishedTags();
    switch (_target) {
      case Target.release:
        _versionRecommended =
            _versionPubspec.plusPatch().copyWith(build: ++build);
        break;
      case Target.test:
        _versionRecommended = _versionPubspec.copyWith(build: ++build);
        break;
      case null:
        throw 'target is null';
    }
  }

  Future<int> _getMajorBuildFromPublishedTags() async {
    final result = await shell.run('git tag --list');
    final builds = result.outLines
        .map((e) => int.tryParse(e.split(RegExp('[+|-]')).last))
        .whereType<int>()
        .toList();
    builds.sort();
    return builds.last;
  }

  void _getVersionFromUser() {
    stdout.writeln('Current version: ${_versionPubspec.toStringFormatted()}');
    stdout.writeln(
        'Set version to release. (recommended "${_versionRecommended?.toStringFormatted()}", press enter to use recommended)');

    var versionInputted = stdin.readLineSync();
    if (versionInputted == null) return _getVersionFromUser();
    if (versionInputted.isEmpty) {
      _versionFromUser = _versionRecommended;
      pubspecInfo.version = _versionFromUser!.toStringFormatted();
      return;
    }

    try {
      _versionFromUser = Version.parse(versionInputted);
      pubspecInfo.version = versionInputted;
    } catch (e) {
      stdout.writeln(e);
      return _getVersionFromUser();
    }
  }

  Future<void> _commitVersion() async {
    final status = await shell.run('git status');
    if (!status.outText.contains('Changes not staged for commit')) return;
    _commitMessage ??= 'bump version to deploy';
    stdout.write('Set commit message("$_commitMessage"): ');
    final inputCommit = stdin.readLineSync() ?? '';
    if (inputCommit.isNotEmpty) _commitMessage = inputCommit;
    await shell.run('git add .');
    await shell.run('git commit --message "$_commitMessage"');
    await shell.run('git push origin');
  }

  void _setPubspecVersionFromUser() {
    final versionFromUserLocal = _versionFromUser?.toStringFormatted();
    if (versionFromUserLocal == null) throw 'versionFromUserLocal is null';
    pubspecInfo.version = versionFromUserLocal;
  }

  Future<void> _createTag() async {
    final tag = _getTagName();
    await shell.run('git tag $tag');
    await shell.run('git push --tags');
  }

  String _getTagName() {
    final versionFromUserLocal = _versionFromUser;
    if (versionFromUserLocal == null) throw 'versionFromUserLocal is null';
    switch (_target) {
      case Target.release:
        return 'v${versionFromUserLocal.toStringFormatted()}';
      case Target.test:
        final name = _getHMLTagName();
        return 'hml-$name-build-${versionFromUserLocal.build}';
      case null:
        throw 'target is null';
    }
  }

  String _getHMLTagName() {
    stdout.write('Set build message(hml-{message}-build-{build_number}): ');
    final inputName = stdin.readLineSync() ?? '';
    if (inputName.isEmpty) return _getHMLTagName();
    return inputName;
  }

  void _setPubspecVersionToOriginal() {
    final versionFromPubspec = _versionPubspec.toStringFormatted();
    if (versionFromPubspec == pubspecInfo.version) return;
    pubspecInfo.version = versionFromPubspec;
  }
}

enum Target { release, test }
