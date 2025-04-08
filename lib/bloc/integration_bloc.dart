import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:process_run/process_run.dart';
import 'integration_event.dart';
import 'integration_state.dart';
import '../utils/project_utils.dart';

class IntegrationBloc extends Bloc<IntegrationEvent, IntegrationState> {
  IntegrationBloc() : super(const IntegrationState()) {
    on<SelectProjectDirectory>(_onSelectProjectDirectory);
    on<ValidateProjectDirectory>(_onValidateProjectDirectory);
    on<IntegrateGoogleMapsPackage>(_onIntegrateGoogleMapsPackage);
    on<SetGoogleMapsApiKey>(_onSetGoogleMapsApiKey);
    on<ConfigurePlatforms>(_onConfigurePlatforms);
    on<AddDemoCode>(_onAddDemoCode);
  }

  Future<void> _onSelectProjectDirectory(
      SelectProjectDirectory event,
      Emitter<IntegrationState> emit,
      ) async {
    emit(state.copyWith(
      status: IntegrationStatus.selecting,
      projectPath: event.path,
    ));
    add(const ValidateProjectDirectory());
  }

  Future<void> _onValidateProjectDirectory(
      ValidateProjectDirectory event,
      Emitter<IntegrationState> emit,
      ) async {
    if (state.projectPath == null) {
      emit(state.copyWith(
        status: IntegrationStatus.error,
        errorMessage: "No project path selected",
      ));
      return;
    }

    emit(state.copyWith(status: IntegrationStatus.validating));

    final projectPath = state.projectPath!;
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));

    if (!pubspecFile.existsSync()) {
      emit(state.copyWith(
        status: IntegrationStatus.error,
        errorMessage: "Invalid Flutter project directory. pubspec.yaml not found.",
      ));
      return;
    }

    try {
      final pubspecContent = pubspecFile.readAsStringSync();
      final pubspec = loadYaml(pubspecContent);

      if (pubspec['dependencies'] == null || pubspec['dependencies']['flutter'] == null) {
        emit(state.copyWith(
          status: IntegrationStatus.error,
          errorMessage: "Not a valid Flutter project.",
        ));
        return;
      }

      // Check if google_maps_flutter is already included
      final hasGoogleMaps = pubspec['dependencies']['google_maps_flutter'] != null;

      emit(state.copyWith(
        status: IntegrationStatus.configuringApiKey,
        isPackageAdded: hasGoogleMaps,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IntegrationStatus.error,
        errorMessage: "Error validating project: ${e.toString()}",
      ));
    }
  }

  Future<void> _onIntegrateGoogleMapsPackage(
      IntegrateGoogleMapsPackage event,
      Emitter<IntegrationState> emit,
      ) async {
    if (state.projectPath == null) {
      emit(state.copyWith(
        status: IntegrationStatus.error,
        errorMessage: "No project path selected",
      ));
      return;
    }

    emit(state.copyWith(status: IntegrationStatus.integrating));

    try {
      final projectPath = state.projectPath!;

      // Only add the package if it's not already added
      if (!state.isPackageAdded) {
        // Add google_maps_flutter to pubspec.yaml
        await ProjectUtils.addPackageToPubspec(
            projectPath,
            'google_maps_flutter',
            '^2.12.1'
        );

    // Run flutter pub get
        final shell = Shell();
        await shell.cd(projectPath).run('flutter pub get');
      }

      emit(state.copyWith(
        status: IntegrationStatus.configuringApiKey,
        isPackageAdded: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IntegrationStatus.error,
        errorMessage: "Error integrating package: ${e.toString()}",
      ));
    }
  }

  Future<void> _onSetGoogleMapsApiKey(
      SetGoogleMapsApiKey event,
      Emitter<IntegrationState> emit,
      ) async {
    emit(state.copyWith(
      status: IntegrationStatus.configuringPlatforms,
      apiKey: event.apiKey,
    ));
    add(const ConfigurePlatforms());
  }

  Future<void> _onConfigurePlatforms(
      ConfigurePlatforms event,
      Emitter<IntegrationState> emit,
      ) async {
    if (state.projectPath == null || state.apiKey == null) {
      emit(state.copyWith(
        status: IntegrationStatus.error,
        errorMessage: "Missing project path or API key",
      ));
      return;
    }

    final projectPath = state.projectPath!;
    final apiKey = state.apiKey!;

    try {
      // Configure Android
      final androidConfigured = await ProjectUtils.configureAndroid(projectPath, apiKey);

      // Configure iOS
      final iosConfigured = await ProjectUtils.configureIOS(projectPath, apiKey);

      emit(state.copyWith(
        status: IntegrationStatus.addingDemo,
        isAndroidConfigured: androidConfigured,
        isIOSConfigured: iosConfigured,
      ));

      add(const AddDemoCode());
    } catch (e) {
      emit(state.copyWith(
        status: IntegrationStatus.error,
        errorMessage: "Error configuring platforms: ${e.toString()}",
      ));
    }
  }

  Future<void> _onAddDemoCode(
      AddDemoCode event,
      Emitter<IntegrationState> emit,
      ) async {
    if (state.projectPath == null) {
      emit(state.copyWith(
        status: IntegrationStatus.error,
        errorMessage: "No project path selected",
      ));
      return;
    }

    try {
      final projectPath = state.projectPath!;

      // Add demo code
      final demoAdded = await ProjectUtils.addGoogleMapsDemo(projectPath);

      emit(state.copyWith(
        status: IntegrationStatus.completed,
        isDemoAdded: demoAdded,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: IntegrationStatus.error,
        errorMessage: "Error adding demo code: ${e.toString()}",
      ));
    }
  }
}