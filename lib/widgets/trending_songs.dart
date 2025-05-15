import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/audio_providers.dart';
import '../widgets/album_artwork.dart';
import '../services/audio_service.dart';

class TrendingSongs extends ConsumerStatefulWidget {
  const TrendingSongs({Key? key}) : super(key: key);

  @override
  ConsumerState<TrendingSongs> createState() => _TrendingSongsState();
}

class _TrendingSongsState extends ConsumerState<TrendingSongs> {
  List<SongModel> _songs = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSongs();
  }
  
  Future<void> _loadSongs() async {
    final audioService = ref.read(audioServiceProvider);
    try {
      final songs = await audioService.getSongs();
      // Limit to first 10 songs for trending section
      final trendingSongs = songs.take(10).toList();
      setState(() {
        _songs = trendingSongs;
        _isLoading = false;
      });
      ref.read(songsProvider.notifier).setSongs(songs);
    } catch (e) {
      print('Error loading songs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioServiceProvider);
    final playerState = ref.watch(playerStateProvider);
    final currentSong = ref.watch(currentSongProvider);
    
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trending right now',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }
    
    if (_songs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trending right now',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('No songs found on your device'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trending right now',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _songs.length,
          itemBuilder: (context, index) {
            final song = _songs[index];
            final isPlaying = currentSong?.id == song.id && 
                             playerState == PlayerState.playing;
            
            return ListTile(
              leading: AlbumArtwork(
                id: song.id,
                type: ArtworkType.AUDIO,
                width: 50,
                height: 50,
                borderRadius: BorderRadius.circular(4),
              ),
              title: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                  color: isPlaying ? Colors.pink[300] : null,
                ),
              ),
              subtitle: Text(
                song.artist ?? 'Unknown Artist',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_formatDuration(Duration(milliseconds: song.duration ?? 0))),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      Icons.favorite_border,
                      color: Colors.white70,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              onTap: () async {
                ref.read(currentSongProvider.notifier).state = song;
                ref.read(playerStateProvider.notifier).state = PlayerState.playing;
                
                // Update duration
                final duration = Duration(milliseconds: song.duration ?? 0);
                ref.read(durationProvider.notifier).state = duration;
                
                // Play the actual song
                await audioService.playSong(song);
              },
            );
          },
        ),
      ],
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
