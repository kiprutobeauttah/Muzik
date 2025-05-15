import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/playlist_provider.dart';
import '../screens/playlist_detail_screen.dart';
import '../screens/create_playlist_screen.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:io';
import '../models/playlist_model.dart';
import '../screens/create_playlist_screen.dart';
import '../screens/playlist_detail_screen.dart';

class Playlists extends ConsumerWidget {
  const Playlists({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Playlists',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePlaylistScreen(),
                      ),
                    );
                  },
                  tooltip: 'Create Playlist',
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: playlistsAsync.when(
            data: (playlists) {
              if (playlists.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No playlists yet',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create Playlist'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreatePlaylistScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink[300],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistDetailScreen(playlistId: playlist.id!),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPlaylistCover(playlist, ref),
                          const SizedBox(height: 8),
                          Text(
                            playlist.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          FutureBuilder<int>(
                            future: ref.read(databaseProvider).getPlaylistSongCount(playlist.id!),
                            builder: (context, snapshot) {
                              final songCount = snapshot.data ?? 0;
                              return Text(
                                '$songCount songs',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistCover(PlaylistModel playlist, WidgetRef ref) {
    if (playlist.coverArt != null) {
      // If the playlist has a cover art, show it
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: FileImage(File(playlist.coverArt!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      // Otherwise, show a placeholder with the first song's artwork if available
      return FutureBuilder<List<int>>(
        future: ref.read(databaseProvider).getPlaylistSongIds(playlist.id!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final firstSongId = snapshot.data!.first;
            return QueryArtworkWidget(
              id: firstSongId,
              type: ArtworkType.AUDIO,
              artworkBorder: BorderRadius.circular(16),
              artworkWidth: 120,
              artworkHeight: 120,
              nullArtworkWidget: _buildDefaultCover(playlist),
            );
          } else {
            return _buildDefaultCover(playlist);
          }
        },
      );
    }
  }

  Widget _buildDefaultCover(PlaylistModel playlist) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.primaries[playlist.name.hashCode % Colors.primaries.length],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 40,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }
}
