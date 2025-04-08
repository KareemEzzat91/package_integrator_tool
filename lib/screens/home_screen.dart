import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/integration_bloc.dart';
import '../bloc/integration_event.dart';
import '../bloc/integration_state.dart';
import 'widgets/step_container.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Package Integrator'),
        centerTitle: true,
      ),
      body: BlocBuilder<IntegrationBloc, IntegrationState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildDirectorySelection(context, state),
                  const SizedBox(height: 16),
                  if (state.projectPath != null)
                    _buildStatusSection(context, state),
                  if (state.status == IntegrationStatus.error)
                    _buildErrorSection(state),
                  if (state.status == IntegrationStatus.completed)
                    _buildCompletionSection(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Google Maps Flutter Integration',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'This tool will help you integrate Google Maps into your Flutter project with minimal effort.',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDirectorySelection(BuildContext context, IntegrationState state) {
    return StepContainer(
      title: '1. Select Flutter Project',
      isActive: state.status == IntegrationStatus.initial ||
          state.status == IntegrationStatus.selecting,
      isCompleted: state.projectPath != null &&
          state.status != IntegrationStatus.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.projectPath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Selected project: ${state.projectPath}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ElevatedButton.icon(
            icon: const Icon(Icons.folder_open),
            label: const Text('Select Flutter Project'),
            onPressed: () async {
              final selectedDirectory = await FilePicker.platform.getDirectoryPath(
                dialogTitle: 'Select Flutter Project Directory',
              );
              if (selectedDirectory != null) {
                context.read<IntegrationBloc>().add(
                    SelectProjectDirectory(selectedDirectory)
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, IntegrationState state) {
    return Column(
      children: [
        _buildPackageIntegration(context, state),
        const SizedBox(height: 16),
        _buildApiKeySection(context, state),
        const SizedBox(height: 16),
        _buildPlatformConfiguration(context, state),
        const SizedBox(height: 16),
        _buildDemoSection(context, state),
      ],
    );
  }
  Widget _buildPackageIntegration(BuildContext context, IntegrationState state) {
    return StepContainer(
      title: '2. Integrate Google Maps Package',
      isActive: state.status == IntegrationStatus.integrating,
      isCompleted: state.isPackageAdded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This step will add the google_maps_flutter package to your pubspec.yaml and run flutter pub get.',
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: state.status == IntegrationStatus.validating ||
                state.status == IntegrationStatus.configuringApiKey && !state.isPackageAdded
                ? () {
              context.read<IntegrationBloc>().add(
                  const IntegrateGoogleMapsPackage()
              );
            }
                : null,
            child: const Text('Add Package'),
          ),
          if (state.isPackageAdded)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '✓ google_maps_flutter package added successfully',
                style: TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildApiKeySection(BuildContext context, IntegrationState state) {
    final apiKeyController = TextEditingController(text: state.apiKey);

    return StepContainer(
      title: '3. Configure Google Maps API Key',
      isActive: state.status == IntegrationStatus.configuringApiKey ||
          state.status == IntegrationStatus.integrating && state.isPackageAdded,
      isCompleted: state.apiKey != null && state.status != IntegrationStatus.configuringApiKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your Google Maps API key. You can get one from the Google Cloud Console.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: apiKeyController,
            decoration: const InputDecoration(
              labelText: 'Google Maps API Key',
              border: OutlineInputBorder(),
              hintText: 'Enter your API key here',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: state.status == IntegrationStatus.configuringApiKey
                    ? () {
                  context.read<IntegrationBloc>().add(
                      SetGoogleMapsApiKey(apiKeyController.text)
                  );
                }
                    : null,
                child: const Text('Set API Key'),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: state.status == IntegrationStatus.configuringApiKey
                    ? () {
                  context.read<IntegrationBloc>().add(
                      const SetGoogleMapsApiKey('YOUR_API_KEY_HERE')
                  );
                }
                    : null,
                child: const Text('Skip (Use placeholder)'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformConfiguration(BuildContext context, IntegrationState state) {
    return StepContainer(
      title: '4. Configure Platforms',
      isActive: state.status == IntegrationStatus.configuringPlatforms,
      isCompleted: (state.isAndroidConfigured || state.isIOSConfigured) &&
          state.status != IntegrationStatus.configuringPlatforms,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This step will configure Android and iOS platforms for Google Maps.',
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: state.status == IntegrationStatus.configuringPlatforms
                ? () {
              context.read<IntegrationBloc>().add(
                  const ConfigurePlatforms()
              );
            }
                : null,
            child: const Text('Configure Platforms'),
          ),
          if (state.isAndroidConfigured)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '✓ Android configured successfully',
                style: TextStyle(color: Colors.green),
              ),
            ),
          if (state.isIOSConfigured)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '✓ iOS configured successfully',
                style: TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDemoSection(BuildContext context, IntegrationState state) {
    return StepContainer(
      title: '5. Add Google Maps Demo',
      isActive: state.status == IntegrationStatus.addingDemo,
      isCompleted: state.isDemoAdded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This step will add a simple Google Maps demo to your project.',
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: state.status == IntegrationStatus.addingDemo && !state.isDemoAdded
                ? () {
              context.read<IntegrationBloc>().add(
                  const AddDemoCode()
              );
            }
                : null,
            child: const Text('Add Demo'),
          ),
          if (state.isDemoAdded)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '✓ Google Maps demo added successfully',
                style: TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(IntegrationState state) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Error',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.errorMessage ?? 'An unknown error occurred',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionSection(IntegrationState state) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Integration Complete!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Google Maps has been successfully integrated into your Flutter project. You can now run your project and see the Google Maps in action.',
            style: TextStyle(color: Colors.green),
          ),
          const SizedBox(height: 16),
          const Text(
            'Next Steps:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Review the generated code in lib/google_maps_demo.dart\n'
                '2. Customize the map as needed\n'
                '3. Run your project on Android or iOS device/emulator',
            style: TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }
}

