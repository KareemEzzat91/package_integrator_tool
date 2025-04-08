import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class ProjectUtils {
  static Future<bool> addPackageToPubspec(
      String projectPath,
      String packageName,
      String version
      ) async {
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw Exception('pubspec.yaml not found');
    }

    String content = pubspecFile.readAsStringSync();

    final pubspec = loadYaml(content);
    if (pubspec['dependencies'] != null &&
        pubspec['dependencies'][packageName] != null) {
      return true;
    }

    final dependenciesIndex = content.indexOf('dependencies:');
    if (dependenciesIndex == -1) {
      throw Exception('Could not find dependencies section in pubspec.yaml');
    }

    int insertIndex = content.indexOf('\n', dependenciesIndex);
    if (insertIndex == -1) {
      insertIndex = content.length;
    }

    final newContent = '${content.substring(0, insertIndex)}\n  $packageName: ^$version${content.substring(insertIndex)}';

    pubspecFile.writeAsStringSync(newContent);
    return true;
  }

  static Future<bool> configureAndroid(String projectPath, String apiKey) async {
    final manifestFile = File(path.join(
        projectPath,
        'android',
        'app',
        'src',
        'main',
        'AndroidManifest.xml'
    ));

    if (!manifestFile.existsSync()) {
      throw Exception('AndroidManifest.xml not found');
    }

    String manifestContent = manifestFile.readAsStringSync();

    if (manifestContent.contains('com.google.android.geo.API_KEY')) {
      final regex = RegExp(r'android:value="(.*)"/>.*com\.google\.android\.geo\.API_KEY');
      if (regex.hasMatch(manifestContent)) {
        manifestContent = manifestContent.replaceAllMapped(
            regex,
                (match) => 'android:value="$apiKey"/><!-- com.google.android.geo.API_KEY'
        );
      } else {
        final applicationTagEnd = manifestContent.indexOf('</application>');
        if (applicationTagEnd == -1) {
          throw Exception('Could not find application tag in AndroidManifest.xml');
        }

        manifestContent = '${manifestContent.substring(0, applicationTagEnd)}        <meta-data\n            android:name="com.google.android.geo.API_KEY"\n            android:value="$apiKey"/>\n${manifestContent.substring(applicationTagEnd)}';
      }
    } else {
      final applicationTagEnd = manifestContent.indexOf('</application>');
      if (applicationTagEnd == -1) {
        throw Exception('Could not find application tag in AndroidManifest.xml');
      }

      manifestContent = '${manifestContent.substring(0, applicationTagEnd)}        <meta-data\n            android:name="com.google.android.geo.API_KEY"\n            android:value="$apiKey"/>\n${manifestContent.substring(applicationTagEnd)}';
    }

    manifestFile.writeAsStringSync(manifestContent);

    final buildGradleFile = File(path.join(
        projectPath,
        'android',
        'app',
        'build.gradle'
    ));

    if (!buildGradleFile.existsSync()) {
      throw Exception('build.gradle not found');
    }

    String buildGradleContent = buildGradleFile.readAsStringSync();

    final minSdkRegex = RegExp(r'minSdkVersion (\d+)');
    final match = minSdkRegex.firstMatch(buildGradleContent);

    if (match != null) {
      final currentMinSdk = int.tryParse(match.group(1) ?? '0') ?? 0;
      if (currentMinSdk < 20) {
        buildGradleContent = buildGradleContent.replaceFirst(
            minSdkRegex,
            'minSdkVersion 20'
        );
        buildGradleFile.writeAsStringSync(buildGradleContent);
      }
    }

    return true;
  }

  static Future<bool> configureIOS(String projectPath, String apiKey) async {
    final infoPlistFile = File(path.join(
        projectPath,
        'ios',
        'Runner',
        'Info.plist'
    ));

    if (!infoPlistFile.existsSync()) {
      throw Exception('Info.plist not found');
    }

    String plistContent = infoPlistFile.readAsStringSync();

    if (!plistContent.contains('GoogleMapsApiKey')) {
      final dictEnd = plistContent.lastIndexOf('</dict>');
      if (dictEnd == -1) {
        throw Exception('Could not find closing dict tag in Info.plist');
      }

      plistContent = '${plistContent.substring(0, dictEnd)}\t<key>GoogleMapsApiKey</key>\n\t<string>$apiKey</string>\n${plistContent.substring(dictEnd)}';

      infoPlistFile.writeAsStringSync(plistContent);
    }

    final appDelegateFile = File(path.join(
        projectPath,
        'ios',
        'Runner',
        'AppDelegate.swift'
    ));

    if (!appDelegateFile.existsSync()) {
      throw Exception('AppDelegate.swift not found');
    }

    String appDelegateContent = appDelegateFile.readAsStringSync();

    if (!appDelegateContent.contains('GMSServices.provideAPIKey')) {
      final appFunctionRegex = RegExp(r'application\(.*didFinishLaunchingWithOptions.*\{');
      final match = appFunctionRegex.firstMatch(appDelegateContent);

      if (match == null) {
        throw Exception('Could not find application function in AppDelegate.swift');
      }

      final insertIndex = match.end;

      if (!appDelegateContent.contains('import GoogleMaps')) {
        appDelegateContent = 'import GoogleMaps\n$appDelegateContent';
      }

      appDelegateContent = '${appDelegateContent.substring(0, insertIndex)}\n    GMSServices.provideAPIKey("$apiKey")\n${appDelegateContent.substring(insertIndex)}';

      appDelegateFile.writeAsStringSync(appDelegateContent);
    }

    final podfileFile = File(path.join(
        projectPath,
        'ios',
        'Podfile'
    ));

    if (podfileFile.existsSync()) {
      String podfileContent = podfileFile.readAsStringSync();

      final platformRegex = RegExp(r"platform :ios, '(.+)'");
      final match = platformRegex.firstMatch(podfileContent);

      if (match != null) {
        final currentVersion = match.group(1) ?? '0.0';
        final currentVersionNum = double.tryParse(currentVersion) ?? 0.0;

        if (currentVersionNum < 12.0) {
          podfileContent = podfileContent.replaceFirst(
              platformRegex,
              "platform :ios, '12.0'"
          );
          podfileFile.writeAsStringSync(podfileContent);
        }
      }
    }

    return true;
  }

  /// Add Google Maps demo code
  static Future<bool> addGoogleMapsDemo(String projectPath) async {
    // Create demo page class
    final googleMapsDemoFile = File(path.join(
        projectPath,
        'lib',
        'google_maps_demo.dart'
    ));

    final demoPageContent = '''
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

// Events
abstract class MapEvent {}

class MapInitialized extends MapEvent {}
class MapCameraMove extends MapEvent {
  final CameraPosition position;
  MapCameraMove(this.position);
}

// States
class MapState {
  final CameraPosition position;
  final Set<Marker> markers;
  
  MapState({
    this.position = const CameraPosition(
      target: LatLng(37.42796133580664, -122.085749655962),
      zoom: 14.4746,
    ),
    this.markers = const {},
  });
  
  MapState copyWith({
    CameraPosition? position,
    Set<Marker>? markers,
  }) {
    return MapState(
      position: position ?? this.position,
      markers: markers ?? this.markers,
    );
  }
}

// BLoC
class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc() : super(MapState()) {
    on<MapInitialized>(_onMapInitialized);
    on<MapCameraMove>(_onMapCameraMove);
  }
  
  void _onMapInitialized(MapInitialized event, Emitter<MapState> emit) {
    final initialMarkers = <Marker>{
      Marker(
        markerId: const MarkerId('google_plex'),
        position: state.position.target,
        infoWindow: const InfoWindow(
          title: 'Google Plex',
          snippet: 'Google Headquarters',
        ),
      ),
    };
    
    emit(state.copyWith(markers: initialMarkers));
  }
  
  void _onMapCameraMove(MapCameraMove event, Emitter<MapState> emit) {
    emit(state.copyWith(position: event.position));
  }
}

class GoogleMapsDemo extends StatelessWidget {
  const GoogleMapsDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MapBloc()..add(MapInitialized()),
      child: const _GoogleMapsDemoView(),
    );
  }
}

class _GoogleMapsDemoView extends StatelessWidget {
  const _GoogleMapsDemoView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Demo'),
      ),
      body: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          return GoogleMap(
            initialCameraPosition: state.position,
            markers: state.markers,
            onMapCreated: (GoogleMapController controller) {
              // You could store the controller in the bloc if needed
            },
            onCameraMove: (CameraPosition position) {
              context.read<MapBloc>().add(MapCameraMove(position));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.center_focus_strong),
        onPressed: () {
          // Add functionality to center on user location, etc.
        },
      ),
    );
  }
}
''';

    googleMapsDemoFile.writeAsStringSync(demoPageContent);

    final mainFile = File(path.join(projectPath, 'lib', 'main.dart'));

    if (!mainFile.existsSync()) {
      throw Exception('main.dart not found');
    }

    String mainContent = mainFile.readAsStringSync();

    if (!mainContent.contains("import 'google_maps_demo.dart'")) {
      final lastImportIndex = mainContent.lastIndexOf('import ');
      if (lastImportIndex != -1) {
        final endOfLine = mainContent.indexOf('\n', lastImportIndex);
        mainContent = "${mainContent.substring(0, endOfLine + 1)}import 'google_maps_demo.dart';\n${mainContent.substring(endOfLine + 1)}";
      } else {
        mainContent = "import 'google_maps_demo.dart';\n$mainContent";
      }
    }

    // Replace the home page with the Google Maps demo
    final homeRegex = RegExp(r'home: .*,');
    if (homeRegex.hasMatch(mainContent)) {
      mainContent = mainContent.replaceFirst(
          homeRegex,
          'home: const GoogleMapsDemo(),'
      );
    }

    mainFile.writeAsStringSync(mainContent);

    return true;
  }
}