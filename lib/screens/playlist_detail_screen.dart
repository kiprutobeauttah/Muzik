import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:io';
import '../models/playlist_model.dart';
import '../providers/playlist_provider.dart';
import '../providers/queue_provider.dart';
import '../providers/audio_providers.dart';
import '../widgets/album_artwork.dart';
import '../screens/add_songs_screen.dart';
import '../screens/edit_playlist_screen.dart';
import '../screens/queue_screen.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final int playlistId;

  const PlaylistDetailScreen({
    Key? key,
    required this.playlistId,
  }) : super(key: key);

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  List<SongModel> _playlistSongs = [];
  bool _isLoading = true;
  final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  void initState() {
    super.initState();
    _loadPlaylistSongs();
  }

  Future<void> _loadPlaylistSongs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbHelper = ref.read(databaseProvider);
      final songIds = await dbHelper.getPlaylistSongIds(widget.playlistId);
      
      if (songIds.isEmpty) {
        setState(() {
          _playlistSongs = [];
          _isLoading = false;
        });
        return;
      }
      
      // Get all songs from device
      final allSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
      
      // Filter songs that are in the playlist
      final playlistSongs = allSongs.where((song) => songIds.contains(song.id)).toList();
      
      // Sort songs according to the order in songIds
      playlistSongs.sort((a, b) {
        final indexA = songIds.indexOf(a.id);
        final indexB = songIds.indexOf(b.id);
        return indexA.compareTo(indexB);
      });
      
      setState(() {
        _playlistSongs = playlistSongs;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading playlist songs: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addSongsToPlaylist() async {
    final result = await Navigator.push<List<SongModel>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddSongsScreen(playlistId: widget.playlistId),
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      final dbHelper = ref.read(databaseProvider);
      
      for (final song in result) {
        await dbHelper.addSongToPlaylist(widget.playlistId, song.id);
      }
      
      // Refresh playlist songs
      _loadPlaylistSongs();
      
      // Refresh playlist counts
      ref.refresh(playlistSongCountProvider(widget.playlistId));
    }
  }

  Future<void> _removeSongFromPlaylist(SongModel song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Song'),
        content: Text('Remove "${song.title}" from this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final dbHelper = ref.read(databaseProvider);
      await dbHelper.removeSongFromPlaylist(widget.playlistId, song.id);
      
      // Refresh playlist songs
      _loadPlaylistSongs();
      
      // Refresh playlist counts
      ref.refresh(playlistSongCountProvider(widget.playlistId));
    }
  }

  Future<void> _deletePlaylist() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: const Text('Are you sure you want to delete this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final dbHelper = ref.read(databaseProvider);
      await dbHelper.deletePlaylist(widget.playlistId);
      
      // Refresh playlists
      ref.refresh(playlistsProvider);
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _playAllSongs({bool shuffle = false}) {
    if (_playlistSongs.isEmpty) return;
    
    final playlistAsync = ref.read(playlistProvider(widget.playlistId));
    String playlistName = 'Playlist';
    
    playlistAsync.whenData((playlist) {
      if (playlist != null) {
        playlistName = playlist.name;
      }
    });
    
    // Set queue from playlist songs
    ref.read(queueProvider.notifier).setQueueFromPlaylist(
      _playlistSongs, 
      playlistName,
      shuffle: shuffle,
    );
    
    // Navigate to queue screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QueueScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistAsync = ref.watch(playlistProvider(widget.playlistId));
    
    return Scaffold(
      appBar: AppBar(
        title: playlistAsync.when(
          data: (playlist) => Text(playlist?.name ?? 'Playlist'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Playlist'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QueueScreen(),
                ),
              );
            },
            tooltip: 'View Queue',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                playlistAsync.whenData((playlist) {
                  if (playlist != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPlaylistScreen(playlist: playlist),
                      ),
                    ).then((_) {
                      // Refresh playlist data
                      ref.refresh(playlistProvider(widget.playlistId));
                    });
                  }
                });
              } else if (value == 'delete') {
                _deletePlaylist();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit Playlist'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Playlist'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Playlist header
          playlistAsync.when(
            data: (playlist) {
              if (playlist == null) {
                return const SizedBox.shrink();
              }
              
              return Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Playlist cover
                    if (playlist.coverArt != null)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: FileImage(File(playlist.coverArt!)),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.primaries[playlist.name.hashCode % Colors.primaries.length],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.music_note,
                            size: 40,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    const SizedBox(width: 16),
                    
                    // Playlist info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_playlistSongs.length} songs',
                            style: TextStyle(
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Play buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Play All'),
                                  onPressed: _playlistSongs.isEmpty
                                      ? null
                                      : () => _playAllSongs(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink[300],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.shuffle),
                                onPressed: _playlistSongs.isEmpty
                                    ? null
                                    : () => _playAllSongs(shuffle: true),
                                tooltip: 'Shuffle Play',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading playlist')),
          ),
          
          // Songs list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _playlistSongs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_note,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No songs in this playlist',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Songs'),
                              onPressed: _addSongsToPlaylist,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink[300],
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _playlistSongs.length,
                        itemBuilder: (context, index) {
                          final song = _playlistSongs[index];
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
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'remove') {
                                      _removeSongFromPlaylist(song);
                                    } else if (value == 'play_next') {
                                      // Add to queue as next
                                      ref.read(queueProvider.notifier).addToQueue([song], playNext: true);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Added "${song.title}" to play next')),
                                      );
                                    } else if (value == 'add_queue') {
                                      // Add to end of queue
                                      ref.read(queueProvider.notifier).addToQueue([song]);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Added "${song.title}" to queue')),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'play_next',
                                      child: Text('Play Next'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'add_queue',
                                      child: Text('Add to Queue'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'remove',
                                      child: Text('Remove from Playlist'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              // Play this song and add the rest to queue
                              final playlistAsync = ref.read(playlistProvider(widget.playlistId));
                              String playlistName = 'Playlist';
                              
                              playlistAsync.whenData((playlist) {
                                if (playlist != null) {
                                  playlistName = playlist.name;
                                }
                              });
                              
                              // Set queue from playlist songs starting at this index
                              final queueSongs = List<SongModel>.from(_playlistSongs);
                              ref.read(queueProvider.notifier).setQueueFromPlaylist(
                                queueSongs, 
                                playlistName,
                              );
                              
                              // Play the selected song
                              ref.read(queueProvider.notifier).playSongAt(index);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSongsToPlaylist,
        backgroundColor: Colors.pink[300],
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
