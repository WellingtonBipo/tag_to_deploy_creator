import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:process_run/shell.dart';
import 'package:tag_to_deploy_creator/src/pubspec_info.dart';
import 'package:tag_to_deploy_creator/src/tag_to_deploy_creator_base.dart';
import 'package:test/test.dart';

class _Stdin extends Mock implements Stdin {}

class _MockIOOverrides extends IOOverrides {
  _MockIOOverrides(this.stdin);

  @override
  final Stdin stdin;
}

class _MockShell extends Mock implements Shell {}

class _MockPubspecInfo extends Mock implements PubspecInfo {}

void main() {
  late Stdin mockStdin;
  late Shell mockShell;
  late PubspecInfo mockPubspecInfo;
  late TagToDeployCreatorBase tagToDeployCreator;

  setUp(() {
    mockStdin = _Stdin();
    IOOverrides.global = _MockIOOverrides(mockStdin);
    mockShell = _MockShell();
    mockPubspecInfo = _MockPubspecInfo();
    tagToDeployCreator = TagToDeployCreatorBase(
      shell: mockShell,
      pubspecInfo: mockPubspecInfo,
    );
  });

  test('tag to deploy creator ...', () async {
    await tagToDeployCreator.create();
  });
}
