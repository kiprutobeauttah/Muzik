import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';
import 'dart:typed_data';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  service.init();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final albumArtworkCacheProvider = StateProvider<Map<int, Uint8List?>>((ref) {
  return {};
});

class AlbumArtwork extends ConsumerWidget {
  final int id;
  final ArtworkType type;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  const AlbumArtwork({
    Key? key,
    required this.id,
    required this.type,
    this.width = 50,
    this.height = 50,
    this.borderRadius,
    this.placeholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioServiceProvider);
    final artworkCache = ref.watch(albumArtworkCacheProvider);

    // Check if artwork is already cached
    if (artworkCache.containsKey(id)) {
      final artwork = artworkCache[id];
      if (artwork != null) {
        return _buildArtworkImage(artwork);
      } else {
        return _buildPlaceholder();
      }
    }

    // If not cached, fetch the artwork
    return FutureBuilder<Uint8List?>(
      future: type == ArtworkType.ALBUM
          ? audioService.getAlbumArtwork(id)
          : audioService.getSongArtwork(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && 
            snapshot.hasData && 
            snapshot.data != null) {
          // Cache the artwork
          ref.read(albumArtworkCacheProvider.notifier).update(
            (state) => {...state, id: snapshot.data},
          );
          return _buildArtworkImage(snapshot.data!);
        } else {
          return _buildPlaceholder();
        }
      },
    );
  }

  Widget _buildArtworkImage(Uint8List artwork) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: Image.memory(
        artwork,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          child: Container(
            width: width,
            height: height,
            color: Colors.grey[800],
            child: Center(
              child: Icon(
                type == ArtworkType.ALBUM ? Icons.album : Icons.music_note,
                color: Colors.grey[400],
                size: width / 2,
              ),
            ),
          ),
        );
  }
}
