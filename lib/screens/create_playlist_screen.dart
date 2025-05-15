import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist_model.dart';
import '../providers/playlist_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CreatePlaylistScreen extends ConsumerStatefulWidget {
  const CreatePlaylistScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends ConsumerState<CreatePlaylistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _coverImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _coverImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _saveCoverImage() async {
    if (_coverImage == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'playlist_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await _coverImage!.copy('${appDir.path}/$fileName');
    return savedImage.path;
  }

  Future<void> _createPlaylist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final coverArtPath = await _saveCoverImage();
      
      final playlist = PlaylistModel(
        name: _nameController.text.trim(),
        coverArt: coverArtPath,
      );
      
      final dbHelper = ref.read(databaseProvider);
      await dbHelper.createPlaylist(playlist);
      
      // Refresh playlists
      ref.refresh(playlistsProvider);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating playlist: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Playlist'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Cover image picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(16),
                    image: _coverImage != null
                        ? DecorationImage(
                            image: FileImage(_coverImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _coverImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Cover',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Playlist name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a playlist name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Create button
            ElevatedButton(
              onPressed: _isLoading ? null : _createPlaylist,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CREATE PLAYLIST'),
            ),
          ],
        ),
      ),
    );
  }
}
