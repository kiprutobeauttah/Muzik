import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/queue_provider.dart';
import '../widgets/album_artwork.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueProvider);
    final currentIndex = queueState.currentIndex;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Queue'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              queueState.mode == QueueMode.shuffle 
                  ? Icons.shuffle 
                  : Icons.shuffle_outlined,
              color: queueState.mode == QueueMode.shuffle 
                  ? Colors.pink[300] 
                  : Colors.white,
            ),
            onPressed: () {
              ref.read(queueProvider.notifier).toggleShuffle();
            },
            tooltip: 'Shuffle',
          ),
          IconButton(
            icon: Icon(
              queueState.mode == QueueMode.repeat 
                  ? Icons.repeat 
                  : queueState.mode == QueueMode.repeatOne 
                      ? Icons.repeat_one 
                      : Icons.repeat_outlined,
              color: (queueState.mode == QueueMode.repeat || queueState.mode == QueueMode.repeatOne) 
                  ? Colors.pink[300] 
                  : Colors.white,
            ),
            onPressed: () {
              ref.read(queueProvider.notifier).toggleRepeat();
            },
            tooltip: 'Repeat',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                ref.read(queueProvider.notifier).clearQueue();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear Queue'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Queue source info
          if (queueState.queueSource != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                queueState.queueSource!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // Queue list
          Expanded(
            child: queueState.songs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.queue_music,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Queue is empty',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add songs from playlists or albums',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: queueState.playOrder.length,
                    onReorder: (oldIndex, newIndex) {
                      // Handle reordering logic
                      // This is complex with shuffle mode, so we'll implement it later
                    },
                    itemBuilder: (context, index) {
                      final songIndex = queueState.playOrder[index];
                      final song = queueState.songs[songIndex];
                      final isPlaying = index == currentIndex;
                      
                      return Dismissible(
                        key: Key('queue_item_${song.id}_$index'),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16.0),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          ref.read(queueProvider.notifier).removeSong(index);
                        },
                        child: ListTile(
                          leading: Stack(
                            alignment: Alignment.center,
                            children: [
                              AlbumArtwork(
                                id: song.id,
                                type: ArtworkType.AUDIO,
                                width: 50,
                                height: 50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              if (isPlaying)
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
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
                              const SizedBox(width: 8),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle),
                              ),
                            ],
                          ),
                          onTap: () {
                            ref.read(queueProvider.notifier).playSongAt(index);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
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
