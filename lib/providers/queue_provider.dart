import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:math';
import '../providers/audio_providers.dart';
import '../services/audio_service.dart';

// Queue modes
enum QueueMode {
  normal,
  repeat,
  repeatOne,
  shuffle
}

// Queue state class
class QueueState {
  final List<SongModel> songs;
  final List<int> playOrder; // For shuffle mode
  final int currentIndex;
  final QueueMode mode;
  final String? queueSource; // e.g., "Playlist: Summer Hits"

  QueueState({
    required this.songs,
    required this.playOrder,
    required this.currentIndex,
    required this.mode,
    this.queueSource,
  });

  // Current song getter
  SongModel? get currentSong => 
      songs.isNotEmpty && currentIndex >= 0 && currentIndex < playOrder.length 
          ? songs[playOrder[currentIndex]] 
          : null;

  // Check if has next song
  bool get hasNext => 
      songs.isNotEmpty && 
      (mode == QueueMode.repeat || 
       mode == QueueMode.shuffle || 
       currentIndex < playOrder.length - 1);

  // Check if has previous song
  bool get hasPrevious => 
      songs.isNotEmpty && 
      (mode == QueueMode.repeat || 
       mode == QueueMode.shuffle || 
       currentIndex > 0);

  // Get next index based on current mode
  int getNextIndex() {
    if (songs.isEmpty) return -1;
    
    if (mode == QueueMode.repeatOne) {
      return currentIndex;
    }
    
    if (currentIndex < playOrder.length - 1) {
      return currentIndex + 1;
    }
    
    // If we're at the end and in repeat mode, go back to start
    if (mode == QueueMode.repeat || mode == QueueMode.shuffle) {
      return 0;
    }
    
    return -1; // No next song
  }

  // Get previous index based on current mode
  int getPreviousIndex() {
    if (songs.isEmpty) return -1;
    
    if (mode == QueueMode.repeatOne) {
      return currentIndex;
    }
    
    if (currentIndex > 0) {
      return currentIndex - 1;
    }
    
    // If we're at the start and in repeat mode, go to end
    if (mode == QueueMode.repeat || mode == QueueMode.shuffle) {
      return playOrder.length - 1;
    }
    
    return -1; // No previous song
  }

  // Create a new shuffled play order
  List<int> _createShuffledPlayOrder() {
    final random = Random();
    final List<int> newOrder = List.generate(songs.length, (i) => i);
    
    // Fisher-Yates shuffle
    for (int i = newOrder.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      int temp = newOrder[i];
      newOrder[i] = newOrder[j];
      newOrder[j] = temp;
    }
    
    return newOrder;
  }

  // Create a copy with updated properties
  QueueState copyWith({
    List<SongModel>? songs,
    List<int>? playOrder,
    int? currentIndex,
    QueueMode? mode,
    String? queueSource,
  }) {
    return QueueState(
      songs: songs ?? this.songs,
      playOrder: playOrder ?? this.playOrder,
      currentIndex: currentIndex ?? this.currentIndex,
      mode: mode ?? this.mode,
      queueSource: queueSource ?? this.queueSource,
    );
  }

  // Toggle shuffle mode
  QueueState toggleShuffle() {
    if (mode == QueueMode.shuffle) {
      // If already in shuffle, go back to normal with sequential order
      return copyWith(
        mode: QueueMode.normal,
        playOrder: List.generate(songs.length, (i) => i),
        // Keep current song but update its index in the sequential order
        currentIndex: currentSong != null ? songs.indexOf(currentSong!) : 0,
      );
    } else {
      // Enter shuffle mode
      final newPlayOrder = _createShuffledPlayOrder();
      return copyWith(
        mode: QueueMode.shuffle,
        playOrder: newPlayOrder,
        // Keep current song but update its index in the shuffled order
        currentIndex: currentSong != null ? newPlayOrder.indexOf(songs.indexOf(currentSong!)) : 0,
      );
    }
  }

  // Toggle repeat mode
  QueueState toggleRepeat() {
    QueueMode newMode;
    
    switch (mode) {
      case QueueMode.normal:
        newMode = QueueMode.repeat;
        break;
      case QueueMode.repeat:
        newMode = QueueMode.repeatOne;
        break;
      case QueueMode.repeatOne:
        newMode = QueueMode.normal;
        break;
      case QueueMode.shuffle:
        // If in shuffle, keep shuffle but toggle repeat
        if (mode == QueueMode.shuffle) {
          newMode = QueueMode.repeat;
        } else {
          newMode = QueueMode.normal;
        }
        break;
    }
    
    return copyWith(mode: newMode);
  }

  // Add songs to queue
  QueueState addSongs(List<SongModel> newSongs, {bool playNext = false}) {
    if (newSongs.isEmpty) return this;
    
    final List<SongModel> updatedSongs = List.from(songs);
    
    if (playNext && currentIndex >= 0) {
      // Insert after current song
      updatedSongs.insertAll(currentIndex + 1, newSongs);
    } else {
      // Add to end
      updatedSongs.addAll(newSongs);
    }
    
    // Update play order based on mode
    List<int> updatedPlayOrder;
    if (mode == QueueMode.shuffle) {
      // Create new shuffled order but keep current song position
      updatedPlayOrder = _createShuffledPlayOrder();
    } else {
      // Sequential order
      updatedPlayOrder = List.generate(updatedSongs.length, (i) => i);
    }
    
    return QueueState(
      songs: updatedSongs,
      playOrder: updatedPlayOrder,
      currentIndex: currentIndex,
      mode: mode,
      queueSource: queueSource,
    );
  }

  // Remove song from queue
  QueueState removeSong(int index) {
    if (index < 0 || index >= songs.length) return this;
    
    final List<SongModel> updatedSongs = List.from(songs);
    final int actualIndex = playOrder[index];
    updatedSongs.removeAt(actualIndex);
    
    // Update play order and current index
    List<int> updatedPlayOrder;
    int updatedCurrentIndex = currentIndex;
    
    if (mode == QueueMode.shuffle) {
      // Recreate shuffled order
      updatedPlayOrder = List.generate(updatedSongs.length, (i) => i);
      final random = Random();
      for (int i = updatedPlayOrder.length - 1; i > 0; i--) {
        int j = random.nextInt(i + 1);
        int temp = updatedPlayOrder[i];
        updatedPlayOrder[i] = updatedPlayOrder[j];
        updatedPlayOrder[j] = temp;
      }
    } else {
      // Sequential order
      updatedPlayOrder = List.generate(updatedSongs.length, (i) => i);
    }
    
    // Adjust current index if needed
    if (index < currentIndex) {
      updatedCurrentIndex--;
    } else if (index == currentIndex) {
      // If removing current song, stay at same index (will play next song)
      updatedCurrentIndex = min(updatedCurrentIndex, updatedSongs.length - 1);
    }
    
    return QueueState(
      songs: updatedSongs,
      playOrder: updatedPlayOrder,
      currentIndex: max(0, updatedCurrentIndex),
      mode: mode,
      queueSource: queueSource,
    );
  }

  // Clear queue
  QueueState clear() {
    return QueueState(
      songs: [],
      playOrder: [],
      currentIndex: -1,
      mode: mode,
      queueSource: null,
    );
  }

  // Set queue from playlist
  static QueueState fromPlaylist(
    List<SongModel> playlistSongs, 
    QueueMode mode, 
    String playlistName
  ) {
    List<int> initialPlayOrder;
    
    if (mode == QueueMode.shuffle) {
      // Create shuffled order
      final random = Random();
      initialPlayOrder = List.generate(playlistSongs.length, (i) => i);
      for (int i = initialPlayOrder.length - 1; i > 0; i--) {
        int j = random.nextInt(i + 1);
        int temp = initialPlayOrder[i];
        initialPlayOrder[i] = initialPlayOrder[j];
        initialPlayOrder[j] = temp;
      }
    } else {
      // Sequential order
      initialPlayOrder = List.generate(playlistSongs.length, (i) => i);
    }
    
    return QueueState(
      songs: playlistSongs,
      playOrder: initialPlayOrder,
      currentIndex: playlistSongs.isEmpty ? -1 : 0,
      mode: mode,
      queueSource: 'Playlist: $playlistName',
    );
  }
}

// Queue provider
class QueueNotifier extends StateNotifier<QueueState> {
  final AudioService _audioService;
  final Reader _read;
  
  QueueNotifier(this._audioService, this._read) : super(
    QueueState(
      songs: [],
      playOrder: [],
      currentIndex: -1,
      mode: QueueMode.normal,
    )
  );

  // Play a specific song from the queue
  Future<void> playSongAt(int index) async {
    if (index < 0 || index >= state.playOrder.length) return;
    
    state = state.copyWith(currentIndex: index);
    final song = state.currentSong;
    
    if (song != null) {
      _read(currentSongProvider.notifier).state = song;
      _read(playerStateProvider.notifier).state = PlayerState.playing;
      _read(durationProvider.notifier).state = Duration(milliseconds: song.duration ?? 0);
      
      await _audioService.playSong(song);
    }
  }

  // Play next song
  Future<void> playNext() async {
    final nextIndex = state.getNextIndex();
    if (nextIndex >= 0) {
      await playSongAt(nextIndex);
    }
  }

  // Play previous song
  Future<void> playPrevious() async {
    final prevIndex = state.getPreviousIndex();
    if (prevIndex >= 0) {
      await playSongAt(prevIndex);
    }
  }

  // Toggle shuffle mode
  void toggleShuffle() {
    state = state.toggleShuffle();
  }

  // Toggle repeat mode
  void toggleRepeat() {
    state = state.toggleRepeat();
  }

  // Set queue from playlist
  Future<void> setQueueFromPlaylist(List<SongModel> songs, String playlistName, {bool shuffle = false}) async {
    final mode = shuffle ? QueueMode.shuffle : QueueMode.normal;
    state = QueueState.fromPlaylist(songs, mode, playlistName);
    
    // Start playing the first song
    if (state.songs.isNotEmpty) {
      await playSongAt(0);
    }
  }

  // Add songs to queue
  void addToQueue(List<SongModel> songs, {bool playNext = false}) {
    state = state.addSongs(songs, playNext: playNext);
  }

  // Remove song from queue
  void removeSong(int index) {
    state = state.removeSong(index);
  }

  // Clear queue
  void clearQueue() {
    state = state.clear();
  }
}

// Provider for the queue
final queueProvider = StateNotifierProvider<QueueNotifier, QueueState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return QueueNotifier(audioService, ref.read);
});

// Provider for current song from queue
final currentQueueSongProvider = Provider<SongModel?>((ref) {
  final queueState = ref.watch(queueProvider);
  return queueState.currentSong;
});

// Provider for queue status (has next/previous)
final queueStatusProvider = Provider<({bool hasNext, bool hasPrevious})>((ref) {
  final queueState = ref.watch(queueProvider);
  return (hasNext: queueState.hasNext, hasPrevious: queueState.hasPrevious);
});
