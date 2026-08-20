import 'package:doclyvo/core/config/environment_profile.dart';
import 'package:envied/envied.dart';

part 'development_environment_profile.g.dart';

@Envied(
  name: 'DevelopmentEnvironment',
  path: '../../.env-templates/development.env',
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
