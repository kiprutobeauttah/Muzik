import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../providers/audio_providers.dart';
import '../providers/queue_provider.dart';
import '../services/audio_service.dart';
import '../screens/queue_screen.dart';
import 'dart:async';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> with TickerProviderStateMixin {
  late AnimationController _diskController;
  Timer? _positionTimer;
  
  @override
  void initState() {
    super.initState();
    _diskController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    // Start a timer to update position periodically
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _updatePosition();
    });
  }
  
  @override
  void dispose() {
    _diskController.dispose();
    _positionTimer?.cancel();
    super.dispose();
  }
  
  void _updatePosition() {
    final audioService = ref.read(audioServiceProvider);
    final playerState = ref.watch(playerStateProvider);
    
    if (playerState == PlayerState.playing) {
      final position = audioService.player.position;
      ref.read(positionProvider.notifier).state = position;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider);
    final playerState = ref.watch(playerStateProvider);
    final audioService = ref.watch(audioServiceProvider);
    final position = ref.watch(positionProvider);
    final duration = ref.watch(durationProvider);
    final queueState = ref.watch(queueProvider);
    final queueStatus = ref.watch(queueStatusProvider);
    
    if (currentSong == null) {
      return const Scaffold(
        body: Center(
          child: Text('No song is currently playing'),
        ),
      );
    }
    
    // Pause/play disk animation based on player state
    if (playerState == PlayerState.playing) {
      _diskController.forward();
    } else {
      _diskController.stop();
    }
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing'),
        centerTitle: true,
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
            tooltip: 'Queue',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo[900]!,
              Colors.purple[800]!,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Queue source info
              if (queueState.queueSource != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    queueState.queueSource!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[300],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Album artwork with rotation animation
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: RotationTransition(
                    turns: _diskController,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: QueryArtworkWidget(
                        id: currentSong.id,
                        type: ArtworkType.AUDIO,
                        artworkBorder: BorderRadius.circular(10000),
                        artworkWidth: double.infinity,
                        artworkHeight: double.infinity,
                        nullArtworkWidget: CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          child: Icon(
                            Icons.music_note,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Song info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      Text(
                        currentSong.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentSong.artist ?? 'Unknown Artist',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[300],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      
                      // Progress bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                activeTrackColor: Colors.pink[300],
                                inactiveTrackColor: Colors.grey[700],
                                thumbColor: Colors.pink[300],
                                overlayColor: Colors.pink[300]!.withOpacity(0.2),
                              ),
                              child: Slider(
                                min: 0,
                                max: duration.inMilliseconds.toDouble(),
                                value: position.inMilliseconds.toDouble().clamp(
                                  0,
                                  duration.inMilliseconds.toDouble(),
                                ),
                                onChanged: (value) {
                                  final newPosition = Duration(milliseconds: value.toInt());
                                  ref.read(positionProvider.notifier).state = newPosition;
                                  audioService.seekTo(newPosition);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(position)),
                                  Text(_formatDuration(duration)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Player controls
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        queueState.mode == QueueMode.shuffle 
                            ? Icons.shuffle 
                            : Icons.shuffle_outlined,
                        color: queueState.mode == QueueMode.shuffle 
                            ? Colors.pink[300] 
                            : Colors.white70,
                      ),
                      iconSize: 30,
                      onPressed: () {
                        ref.read(queueProvider.notifier).toggleShuffle();
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      iconSize: 40,
                      onPressed: queueStatus.hasPrevious
                          ? () {
                              ref.read(queueProvider.notifier).playPrevious();
                            }
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.pink[300],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                          icon: Icon(
                            playerState == PlayerState.playing
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          iconSize: 40,
                          color: Colors.white,
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
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      iconSize: 40,
                      onPressed: queueStatus.hasNext
                          ? () {
                              ref.read(queueProvider.notifier).playNext();
                            }
                          : null,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        queueState.mode == QueueMode.repeat 
                            ? Icons.repeat 
                            : queueState.mode == QueueMode.repeatOne 
                                ? Icons.repeat_one 
                                : Icons.repeat_outlined,
                        color: (queueState.mode == QueueMode.repeat || queueState.mode == QueueMode.repeatOne) 
                            ? Colors.pink[300] 
                            : Colors.white70,
                      ),
                      iconSize: 30,
                      onPressed: () {
                        ref.read(queueProvider.notifier).toggleRepeat();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
