import 'package:doclyvo/core/config/environment_profile.dart';
import 'package:envied/envied.dart';

part 'release_environment_profile.g.dart';

@Envied(
  name: 'ReleaseEnvironment',
  path: '../../.env-templates/release.env',
)
final class ReleaseEnvironmentProfile extends EnvironmentProfile {
  @override
  @EnviedField(varName: 'BASE_URL')
  final String baseUrl = _ReleaseEnvironment.baseUrl;

  @override
  @EnviedField(varName: 'CLIENT_ID')
  final String clientId = _ReleaseEnvironment.clientId;

  @override
  @EnviedField(varName: 'CLIENT_SECRET')
  final String clientSecret = _ReleaseEnvironment.clientSecret;
}
