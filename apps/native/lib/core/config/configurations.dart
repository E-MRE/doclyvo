import 'package:doclyvo/core/config/development_environment_profile.dart';
import 'package:doclyvo/core/config/environment_profile.dart';
import 'package:doclyvo/core/config/environment_type.dart';
import 'package:doclyvo/core/config/release_environment_profile.dart';

final class Configurations {
  static const EnvironmentType environment = EnvironmentType.development;

  static bool get isDevelopment => environment == EnvironmentType.development;

  static bool get isRelease => environment == EnvironmentType.release;

  static EnvironmentProfile get environmentProfile {
    return switch (environment) {
      EnvironmentType.development => DevelopmentEnvironmentProfile(),
      EnvironmentType.release => ReleaseEnvironmentProfile(),
    };
  }
}
