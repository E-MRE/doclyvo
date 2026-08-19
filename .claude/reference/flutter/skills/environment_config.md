# Environment Configuration

## Architecture

```
environments/
├── development.env   ← dev secrets (not committed to VCS)
└── release.env       ← release secrets (not committed to VCS)

EnvironmentType (enum)         ← release | development
EnvironmentProfile (abstract)  ← baseUrl, clientId, clientSecret
├── DevelopmentEnvironmentProfile (@Envied)
└── ReleaseEnvironmentProfile (@Envied)

EnvironmentTypeExtension       ← .toProfile() switch
Configurations (final class)   ← current environment switch point
```

---

## Configurations — Entry Point

File: `lib/core/config/configurations.dart`

```dart
final class Configurations {
  static const EnvironmentType environment = EnvironmentType.development;
  static bool get isDevelopment => environment == EnvironmentType.development;

  static EnvironmentProfile get environmentProfile => environment.toProfile();
}
```

**Rule**: Change `environment` here to switch between dev/release. Do not switch conditionally in multiple places.

---

## EnvironmentProfile — Abstract Interface

```dart
abstract class EnvironmentProfile {
  String get baseUrl;
  String get clientSecret;
  String get clientId;
}
```

---

## Environment Profiles — `envied` with Obfuscation

`envied` reads from `.env` files at build time and generates obfuscated Dart code.

```dart
@Envied(
  name: 'DevelopmentEnvironment',
  path: 'environments/development.env',
  obfuscate: true,  // ← values are XOR obfuscated in generated code
)
final class DevelopmentEnvironmentProfile extends EnvironmentProfile {
  @override
  @EnviedField(varName: 'BASE_URL')
  final String baseUrl = _DevelopmentEnvironment.baseUrl;

  @override
  @EnviedField(varName: 'CLIENT_ID')
  final String clientId = _DevelopmentEnvironment.clientId;

  @override
  @EnviedField(varName: 'CLIENT_SECRET')
  final String clientSecret = _DevelopmentEnvironment.clientSecret;
}
```

Generated file: `development_environment_profile.g.dart` (committed to VCS, but values are obfuscated).

---

## .env File Format

```env
BASE_URL=https://api.example.com/
CLIENT_ID=your_client_id
CLIENT_SECRET=your_client_secret
```

**Rule**: `.env` files are NOT committed to VCS. Generated `.g.dart` files ARE committed (contain obfuscated values).

---

## Accessing Environment Values

```dart
// Via Configurations
Configurations.environmentProfile.baseUrl
Configurations.environmentProfile.clientId
Configurations.isDevelopment

// Via AppDependency (when registered)
AppDependency.getEnvironment<DevelopmentEnvironmentProfile>().baseUrl
```

---

## Environment Switching in DI

```dart
void registerDependencies(DependencyInjector injector) {
  _registerNetwork(injector);  // network uses Configurations.environmentProfile.baseUrl

  if (Configurations.isDevelopment) {
    injector.registerSingleton<EnvironmentProfile>(DevelopmentEnvironmentProfile());
  } else {
    injector.registerSingleton<EnvironmentProfile>(ReleaseEnvironmentProfile());
  }
}
```

---

## Running build_runner After Env Changes

After modifying `.env` files, regenerate:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Or use the project's script:
```bash
./scripts/build.sh
```

---

## Always / Never

### Always
- Change `Configurations.environment` to switch environment modes
- Use `Configurations.environmentProfile.*` for env values in code
- Keep `.env` files out of VCS
- Commit the generated `.g.dart` files (they're obfuscated)
- Run `build_runner` after modifying `.env` files

### Never
- Hardcode API URLs directly in code — always use `Configurations.environmentProfile.baseUrl`
- Add raw secrets to any Dart file
- Use `Platform.environment` or system env vars — use `envied` profiles
