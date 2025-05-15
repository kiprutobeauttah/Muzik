import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_providers.dart';
import '../providers/queue_provider.dart';
import '../widgets/sidebar_navigation.dart';
import '../widgets/trending_songs.dart';
import '../widgets/top_artists.dart';
import '../widgets/playlists.dart';
import '../widgets/player_controls.dart';
import '../screens/queue_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    // For Android
    if (await Permission.storage.request().isGranted) {
      setState(() => _hasPermission = true);
      _loadMusic();
    } else {
      setState(() => _hasPermission = false);
    }
  }

  Future<void> _loadMusic() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    ref.read(songsProvider.notifier).setSongs(songs);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 900;

    return Scaffold(
      body: !_hasPermission
          ? _buildPermissionRequest()
          : Row(
              children: [
                // Sidebar
                if (isWideScreen) const SidebarNavigation(),
                
                // Main content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.indigo[900]!,
                          Colors.purple[800]!,
                          Colors.blue[900]!,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // App bar with search
                        _buildAppBar(isWideScreen),
                        
                        // Main content area
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const TrendingSongs(),
                                const SizedBox(height: 24),
                                const TopArtists(),
                                const SizedBox(height: 24),
                                const Playlists(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: !isWideScreen && _hasPermission
          ? const SidebarNavigationMobile()
          : null,
      bottomSheet: _hasPermission ? const PlayerControls() : null,
      floatingActionButton: _hasPermission
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QueueScreen(),
                  ),
                );
              },
              backgroundColor: Colors.pink[300],
              child: const Icon(Icons.queue_music),
              tooltip: 'View Queue',
            )
          : null,
    );
  }

  Widget _buildAppBar(bool isWideScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          if (!isWideScreen) ...[
            CircleAvatar(
              backgroundColor: Colors.pink[300],
              child: const Text('M', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            const Text(
              'Music App',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: isWideScreen ? 0 : 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for songs, artists...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Storage permission is required to access your music',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _checkAndRequestPermissions,
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }
}
