import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist_model.dart';
import '../services/database_helper.dart';

final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final playlistsProvider = FutureProvider<List<PlaylistModel>>((ref) async {
  final dbHelper = ref.watch(databaseProvider);
  return await dbHelper.getPlaylists();
});

final playlistProvider = FutureProvider.family<PlaylistModel?, int>((ref, id) async {
  final dbHelper = ref.watch(databaseProvider);
  return await dbHelper.getPlaylist(id);
});

final playlistSongIdsProvider = FutureProvider.family<List<int>, int>((ref, playlistId) async {
  final dbHelper = ref.watch(databaseProvider);
  return await dbHelper.getPlaylistSongIds(playlistId);
});

final playlistSongCountProvider = FutureProvider.family<int, int>((ref, playlistId) async {
  final dbHelper = ref.watch(databaseProvider);
  return await dbHelper.getPlaylistSongCount(playlistId);
});

final isSongInPlaylistProvider = FutureProvider.family<bool, ({int playlistId, int songId})>((ref, params) async {
  final dbHelper = ref.watch(databaseProvider);
  return await dbHelper.isSongInPlaylist(params.playlistId, params.songId);
});
