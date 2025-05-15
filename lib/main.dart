import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'providers/audio_providers.dart';
import 'providers/queue_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0E21),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(
    const ProviderScope(
      child: MusicApp(),
    ),
  );
}

class MusicApp extends ConsumerStatefulWidget {
  const MusicApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends ConsumerState<MusicApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudioService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    final audioService = ref.read(audioServiceProvider);
    
    if (state == AppLifecycleState.paused) {
      // App is in background
      final playerState = ref.read(playerStateProvider);
      if (playerState == PlayerState.playing) {
        // Optionally pause playback when app goes to background
        // audioService.pause();
      }
    }
  }

  Future<void> _initAudioService() async {
    final audioService = ref.read(audioServiceProvider);
    await audioService.init();
    
    // Listen to playback completion to advance queue
    audioService.player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        // Song finished playing, move to next in queue
        ref.read(queueProvider.notifier).playNext();
      }
    });
    
    // Update position and duration
    audioService.player.positionStream.listen((position) {
      ref.read(positionProvider.notifier).state = position;
    });
    
    audioService.player.durationStream.listen((duration) {
      if (duration != null) {
        ref.read(durationProvider.notifier).state = duration;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: Colors.pink[300],
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        colorScheme: ColorScheme.dark(
          primary: Colors.pink[300]!,
          secondary: Colors.pink[200]!,
          background: const Color(0xFF0A0E21),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0A0E21),
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Colors.pink[300],
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            color: Colors.white70,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.pink[300],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink[300],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.pink[300],
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.pink[300],
          thumbColor: Colors.pink[300],
          inactiveTrackColor: Colors.grey[700],
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Check storage permission
    final status = await Permission.storage.status;
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _isLoading = false;
      });
      _navigateToHome();
    } else {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    final status = await Permission.storage.request();
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _isLoading = false;
      });
      _navigateToHome();
    } else {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  void _navigateToHome() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo[900]!,
              Colors.purple[800]!,
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : _hasPermission
                  ? _buildSplashContent()
                  : _buildPermissionRequest(),
        ),
      ),
    );
  }

  Widget _buildSplashContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.pink[300],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.pink[700]!.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.music_note,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Music Player',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your music, your way',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 32),
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ],
    );
  }

  Widget _buildPermissionRequest() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_music,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 24),
          const Text(
            'Storage Permission Required',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'This app needs access to your device storage to find and play music files.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[300],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _requestPermissions,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'Grant Permission',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
