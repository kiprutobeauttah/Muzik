import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import '../models/playlist_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'music_player.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create playlists table
    await db.execute('''
      CREATE TABLE playlists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        coverArt TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Create playlist_songs table (junction table for many-to-many relationship)
    await db.execute('''
      CREATE TABLE playlist_songs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlistId INTEGER NOT NULL,
        songId INTEGER NOT NULL,
        addedAt INTEGER NOT NULL,
        FOREIGN KEY (playlistId) REFERENCES playlists (id) ON DELETE CASCADE,
        UNIQUE(playlistId, songId)
      )
    ''');
  }

  // Playlist operations
  Future<int> createPlaylist(PlaylistModel playlist) async {
    final db = await database;
    return await db.insert('playlists', playlist.toMap());
  }

  Future<List<PlaylistModel>> getPlaylists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('playlists', orderBy: 'updatedAt DESC');
    return List.generate(maps.length, (i) {
      return PlaylistModel.fromMap(maps[i]);
    });
  }

  Future<PlaylistModel?> getPlaylist(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return PlaylistModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updatePlaylist(PlaylistModel playlist) async {
    final db = await database;
    return await db.update(
      'playlists',
      playlist.toMap(),
      where: 'id = ?',
      whereArgs: [playlist.id],
    );
  }

  Future<int> deletePlaylist(int id) async {
    final db = await database;
    return await db.delete(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Playlist songs operations
  Future<int> addSongToPlaylist(int playlistId, int songId) async {
    final db = await database;
    return await db.insert(
      'playlist_songs',
      {
        'playlistId': playlistId,
        'songId': songId,
        'addedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> removeSongFromPlaylist(int playlistId, int songId) async {
    final db = await database;
    return await db.delete(
      'playlist_songs',
      where: 'playlistId = ? AND songId = ?',
      whereArgs: [playlistId, songId],
    );
  }

  Future<List<int>> getPlaylistSongIds(int playlistId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'playlist_songs',
      columns: ['songId'],
      where: 'playlistId = ?',
      whereArgs: [playlistId],
      orderBy: 'addedAt DESC',
    );
    return List.generate(maps.length, (i) => maps[i]['songId'] as int);
  }

  Future<int> getPlaylistSongCount(int playlistId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM playlist_songs WHERE playlistId = ?',
      [playlistId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> isSongInPlaylist(int playlistId, int songId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'playlist_songs',
      where: 'playlistId = ? AND songId = ?',
      whereArgs: [playlistId, songId],
    );
    return result.isNotEmpty;
  }
}
