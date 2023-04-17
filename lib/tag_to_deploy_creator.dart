library tag_to_deploy_creator;

import 'package:process_run/shell.dart';

import 'src/pubspec_info.dart';
import 'src/tag_to_deploy_creator_base.dart';

abstract class TagToDeployCreator {
  factory TagToDeployCreator() => TagToDeployCreatorBase(
        shell: Shell(),
        pubspecInfo: PubspecInfo(),
      );

  Future<void> create();
}
