import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio_background/just_audio_background.dart';

enum ProcessingState {
  idle,
  loading,
  buffering,
  ready,
  completed,
}

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  
  AudioPlayer get player => _audioPlayer;
  
  Future<void> init() async {
    // Configure the audio session for media playback
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    
    // Set up background playback notification
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.example.music_app.channel.audio',
        androidNotificationChannelName: 'Music Player',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
      );
    } catch (e) {
      print('Error initializing background playback: $e');
    }
  }
  
  Future<List<SongModel>> getSongs() async {
    return await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
  }
  
  Future<List<AlbumModel>> getAlbums() async {
    return await _audioQuery.queryAlbums(
      sortType: AlbumSortType.ALBUM,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
  }
  
  Future<List<ArtistModel>> getArtists() async {
    return await _audioQuery.queryArtists(
      sortType: ArtistSortType.ARTIST,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
  }
  
  Future<Uint8List?> getAlbumArtwork(int albumId) async {
    return await _audioQuery.queryArtwork(
      albumId,
      ArtworkType.ALBUM,
      format: ArtworkFormat.JPEG,
      size: 200,
    );
  }
  
  Future<Uint8List?> getSongArtwork(int songId) async {
    return await _audioQuery.queryArtwork(
      songId,
      ArtworkType.AUDIO,
      format: ArtworkFormat.JPEG,
      size: 200,
    );
  }
  
  Future<void> playSong(SongModel song) async {
    try {
      // For Android, we need to get the file path from the URI
      final mediaItem = MediaItem(
        id: song.id.toString(),
        title: song.title,
        artist: song.artist ?? 'Unknown Artist',
        album: song.album,
        duration: Duration(milliseconds: song.duration ?? 0),
        artUri: Uri.parse('file://${song.uri}'),
      );
      
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(song.uri!),
          tag: mediaItem,
        ),
      );
      
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing song: $e');
    }
  }
  
  Future<void> pause() async {
    await _audioPlayer.pause();
  }
  
  Future<void> resume() async {
    await _audioPlayer.play();
  }
  
  Future<void> stop() async {
    await _audioPlayer.stop();
  }
  
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }
  
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }
  
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
