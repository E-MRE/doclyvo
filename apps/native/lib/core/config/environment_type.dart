enum EnvironmentType {
  development,
  release,
}

extension EnvironmentTypeExtension on EnvironmentType {
  bool get isDevelopment => this == EnvironmentType.development;

  bool get isRelease => this == EnvironmentType.release;
}
