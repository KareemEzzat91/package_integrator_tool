import 'package:equatable/equatable.dart';

enum IntegrationStatus {
  initial,
  selecting,
  validating,
  integrating,
  configuringApiKey,
  configuringPlatforms,
  addingDemo,
  completed,
  error
}

class IntegrationState extends Equatable {
  final IntegrationStatus status;
  final String? projectPath;
  final String? apiKey;
  final String? errorMessage;
  final bool isAndroidConfigured;
  final bool isIOSConfigured;
  final bool isDemoAdded;
  final bool isPackageAdded;

  const IntegrationState({
    this.status = IntegrationStatus.initial,
    this.projectPath,
    this.apiKey,
    this.errorMessage,
    this.isAndroidConfigured = false,
    this.isIOSConfigured = false,
    this.isDemoAdded = false,
    this.isPackageAdded = false,
  });

  IntegrationState copyWith({
    IntegrationStatus? status,
    String? projectPath,
    String? apiKey,
    String? errorMessage,
    bool? isAndroidConfigured,
    bool? isIOSConfigured,
    bool? isDemoAdded,
    bool? isPackageAdded,
  }) {
    return IntegrationState(
      status: status ?? this.status,
      projectPath: projectPath ?? this.projectPath,
      apiKey: apiKey ?? this.apiKey,
      errorMessage: errorMessage,
      isAndroidConfigured: isAndroidConfigured ?? this.isAndroidConfigured,
      isIOSConfigured: isIOSConfigured ?? this.isIOSConfigured,
      isDemoAdded: isDemoAdded ?? this.isDemoAdded,
      isPackageAdded: isPackageAdded ?? this.isPackageAdded,
    );
  }

  @override
  List<Object?> get props => [
    status,
    projectPath,
    apiKey,
    errorMessage,
    isAndroidConfigured,
    isIOSConfigured,
    isDemoAdded,
    isPackageAdded
  ];
}