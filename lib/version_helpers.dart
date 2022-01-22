import 'package:pub_semver/pub_semver.dart';

Version versionWithoutBuild(Version version) {
  return Version(
    version.major,
    version.minor,
    version.patch,
    pre: version.preRelease.isEmpty ? null : version.preRelease.join('.'),
  );
}

String versionStringWithoutBuild(String versionStr) {
  return versionWithoutBuild(Version.parse(versionStr)).toString();
}
