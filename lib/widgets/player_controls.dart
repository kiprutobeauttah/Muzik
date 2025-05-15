import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/audio_providers.dart';
import '../providers/queue_provider.dart';
import '../services/audio_service.dart';
import '../screens/now_playing_screen.dart';
import '../screens/queue_screen.dart';
import 'album_artwork.dart';

class PlayerControls extends ConsumerWidget {
  const PlayerControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final playerState = ref.watch(playerStateProvider);
    final audioService = ref.watch(audioServiceProvider);
    final position = ref.watch(positionProvider);
    final duration = ref.watch(durationProvider);
    final queueStatus = ref.watch(queueStatusProvider);

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NowPlayingScreen(),
          ),
        );
      },
      child: Container(
        height: 70,
        color: Colors.black87,
        child: Row(
          children: [
            // Song info with artwork
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                children: [
                  AlbumArtwork(
                    id: currentSong.id,
                    type: ArtworkType.AUDIO,
                    width: 50,
                    height: 50,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentSong.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentSong.artist ?? 'Unknown Artist',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Queue button
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
              tooltip: 'Queue',
            ),

            // Previous button
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: queueStatus.hasPrevious
                  ? () {
                      ref.read(queueProvider.notifier).playPrevious();
                    }
                  : null,
            ),

            // Play/Pause button
            IconButton(
              icon: Icon(
                playerState == PlayerState.playing
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 40,
              ),
              onPressed: () {
                if (playerState == PlayerState.playing) {
                  ref.read(playerStateProvider.notifier).state = PlayerState.paused;
                  audioService.pause();
                } else {
                  ref.read(playerStateProvider.notifier).state = PlayerState.playing;
                  audioService.resume();
                }
              },
            ),

            // Next button
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: queueStatus.hasNext
                  ? () {
                      ref.read(queueProvider.notifier).playNext();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
