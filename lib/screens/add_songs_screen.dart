import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/audio_providers.dart';
import '../providers/playlist_provider.dart';
import '../widgets/album_artwork.dart';

class AddSongsScreen extends ConsumerStatefulWidget {
  final int playlistId;

  const AddSongsScreen({
    Key? key,
    required this.playlistId,
  }) : super(key: key);

  @override
  ConsumerState<AddSongsScreen> createState() => _AddSongsScreenState();
}

class _AddSongsScreenState extends ConsumerState<AddSongsScreen> {
  final List<SongModel> _selectedSongs = [];
  List<SongModel> _allSongs = [];
  List<SongModel> _filteredSongs = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Set<int> _existingSongIds = {};

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all songs
      final audioQuery = OnAudioQuery();
      final songs = await audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );

      // Get existing song IDs in the playlist
      final dbHelper = ref.read(databaseProvider);
      final existingSongIds = await dbHelper.getPlaylistSongIds(widget.playlistId);
      
      setState(() {
        _allSongs = songs;
        _filteredSongs = songs;
        _existingSongIds = existingSongIds.toSet();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading songs: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterSongs(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSongs = _allSongs;
      });
    } else {
      final lowercaseQuery = query.toLowerCase();
      setState(() {
        _filteredSongs = _allSongs.where((song) {
          return song.title.toLowerCase().contains(lowercaseQuery) ||
                 (song.artist ?? '').toLowerCase().contains(lowercaseQuery) ||
                 (song.album ?? '').toLowerCase().contains(lowercaseQuery);
        }).toList();
      });
    }
  }

  void _toggleSongSelection(SongModel song) {
    setState(() {
      if (_selectedSongs.contains(song)) {
        _selectedSongs.remove(song);
      } else {
        _selectedSongs.add(song);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Songs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check),
            label: Text('Add (${_selectedSongs.length})'),
            onPressed: _selectedSongs.isEmpty
                ? null
                : () {
                    Navigator.pop(context, _selectedSongs);
                  },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search songs',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterSongs('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterSongs,
            ),
          ),
          
          // Songs list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSongs.isEmpty
                    ? Center(
                        child: Text(
                          'No songs found',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = _filteredSongs[index];
                          final isSelected = _selectedSongs.contains(song);
                          final isInPlaylist = _existingSongIds.contains(song.id);
                          
                          return ListTile(
                            enabled: !isInPlaylist,
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
                                color: isInPlaylist ? Colors.grey : null,
                              ),
                            ),
                            subtitle: Text(
                              song.artist ?? 'Unknown Artist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isInPlaylist ? Colors.grey[600] : Colors.grey[400],
                              ),
                            ),
                            trailing: isInPlaylist
                                ? const Text('Already in playlist')
                                : Checkbox(
                                    value: isSelected,
                                    onChanged: (value) => _toggleSongSelection(song),
                                    activeColor: Colors.pink[300],
                                  ),
                            onTap: isInPlaylist
                                ? null
                                : () => _toggleSongSelection(song),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
