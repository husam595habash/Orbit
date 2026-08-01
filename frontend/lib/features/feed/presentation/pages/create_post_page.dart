import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/cloudinary_datasource.dart';
import '../providers/feed_provider.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key, this.initialImage});

  /// Image handed off from the camera/gallery screen, shown immediately so
  /// the user lands straight in the caption editor.
  final File? initialImage;

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _captionController = TextEditingController();
  File? _image;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _image = widget.initialImage;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty && _image == null) return;

    final author = ref.read(authViewModelProvider).valueOrNull;
    if (author == null) return;

    setState(() => _isSubmitting = true);
    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await ref
            .read(cloudinaryDataSourceProvider)
            .uploadImage(_image!);
      }
      await ref.read(feedViewModelProvider.notifier).createPost(
            message: caption,
            imageUrl: imageUrl,
            authorName: author.username,
            authorImageUrl: author.imageUrl,
          );
      // Pop back past the camera screen straight to the feed, not just one
      // step to the camera.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from library'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        !_isSubmitting && (_captionController.text.trim().isNotEmpty || _image != null);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('New post'),
        actions: [
          TextButton(
            onPressed: canSubmit ? _submit : null,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Share'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _image != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_image!, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: _RemoveImageButton(
                                onTap: () => setState(() => _image = null),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: AppColors.surfaceDark,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 40),
                                SizedBox(height: 8),
                                Text('Add a photo'),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              maxLines: 4,
              minLines: 3,
              decoration: const InputDecoration(hintText: 'Write a caption...'),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemoveImageButton extends StatelessWidget {
  const _RemoveImageButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 18),
      ),
    );
  }
}
