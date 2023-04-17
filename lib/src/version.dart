class Version {
  const Version({
    required this.major,
    required this.minor,
    required this.patch,
    required this.build,
  });

  final int major;
  final int minor;
  final int patch;
  final int build;

  static Version parse(String version, [String builderSeparator = '+']) {
    final listString = version.split(RegExp('[.|$builderSeparator]'));
    final list = listString.map(int.tryParse).whereType<int>().toList();
    if (list.length == 4) {
      return Version(
        major: list[0],
        minor: list[1],
        patch: list[2],
        build: list[3],
      );
    }
    return throw 'Wrong format $version (Ex: 1.0.0${builderSeparator}1)';
  }

  String toStringFormatted([String builderSeparator = '+']) =>
      '$major.$minor.$patch$builderSeparator$build';

  Version plusPatch() => copyWith(patch: patch + 1);

  Version copyWith({
    int? major,
    int? minor,
    int? patch,
    int? build,
  }) {
    return Version(
      major: major ?? this.major,
      minor: minor ?? this.minor,
      patch: patch ?? this.patch,
      build: build ?? this.build,
    );
  }
}
