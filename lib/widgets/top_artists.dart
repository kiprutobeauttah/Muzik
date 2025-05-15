import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../services/audio_service.dart';
import '../providers/audio_providers.dart';

class TopArtists extends ConsumerStatefulWidget {
  const TopArtists({Key? key}) : super(key: key);

  @override
  ConsumerState<TopArtists> createState() => _TopArtistsState();
}

class _TopArtistsState extends ConsumerState<TopArtists> {
  List<ArtistModel> _artists = [];
  Map<int, List<AlbumModel>> _artistAlbums = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadArtists();
  }
  
  Future<void> _loadArtists() async {
    final audioService = ref.read(audioServiceProvider);
    try {
      final allArtists = await audioService.getArtists();
      final topArtists = allArtists
          .where((artist) => artist.numberOfTracks != null && artist.numberOfTracks! > 0)
          .take(5)
          .toList();
      
      // Also get albums for artist avatars
      for (var artist in topArtists) {
        final albums = await _audioQuery.queryAlbumsFromArtist(
          artistId: artist.id,
        );
        if (albums.isNotEmpty) {
          _artistAlbums[artist.id] = albums;
        }
      }
      
      setState(() {
        _artists = topArtists;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading artists: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioQuery = OnAudioQuery();
    
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Artist',
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
    
    if (_artists.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Artist',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('No artists found'),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Artist',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _artists.length,
            itemBuilder: (context, index) {
              final artist = _artists[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  children: [
                    _artistAlbums.containsKey(artist.id) && _artistAlbums[artist.id]!.isNotEmpty
                        ? QueryArtworkWidget(
                            id: _artistAlbums[artist.id]![0].id,
                            type: ArtworkType.ALBUM,
                            artworkWidth: 120,
                            artworkHeight: 120,
                            artworkBorder: BorderRadius.circular(60),
                            nullArtworkWidget: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[800],
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[800],
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                    const SizedBox(height: 8),
                    Text(
                      artist.artist,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${artist.numberOfTracks} Tracks | ${artist.numberOfAlbums} Albums',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
