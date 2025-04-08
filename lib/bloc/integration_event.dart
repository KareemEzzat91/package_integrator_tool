import 'package:equatable/equatable.dart';

abstract class IntegrationEvent extends Equatable {
  const IntegrationEvent();

  @override
  List<Object?> get props => [];
}

class SelectProjectDirectory extends IntegrationEvent {
  final String path;

  const SelectProjectDirectory(this.path);

  @override
  List<Object?> get props => [path];
}

class ValidateProjectDirectory extends IntegrationEvent {
  const ValidateProjectDirectory();
}

class IntegrateGoogleMapsPackage extends IntegrationEvent {
  const IntegrateGoogleMapsPackage();
}

class SetGoogleMapsApiKey extends IntegrationEvent {
  final String apiKey;

  const SetGoogleMapsApiKey(this.apiKey);

  @override
  List<Object?> get props => [apiKey];
}

class ConfigurePlatforms extends IntegrationEvent {
  const ConfigurePlatforms();
}

class AddDemoCode extends IntegrationEvent {
  const AddDemoCode();
}