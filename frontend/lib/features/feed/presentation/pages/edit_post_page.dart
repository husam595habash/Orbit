import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/post.dart';
import '../providers/feed_provider.dart';

/// Caption-only editor for an existing post — the photo itself can't be
/// changed after posting, matching Instagram's own edit flow.
class EditPostPage extends ConsumerStatefulWidget {
  const EditPostPage({super.key, required this.post});

  final Post post;

  @override
  ConsumerState<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends ConsumerState<EditPostPage> {
  final _captionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _captionController.text = widget.post.message;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final caption = _captionController.text.trim();
    setState(() => _isSubmitting = true);
    try {
      await ref.read(feedViewModelProvider.notifier).updatePost(widget.post.id, caption);
      if (mounted) Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final hasImage =
        widget.post.selectedFile != null && widget.post.selectedFile!.isNotEmpty;
    final changed = _captionController.text.trim() != widget.post.message;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Edit post'),
        actions: [
          TextButton(
            onPressed: !_isSubmitting && changed ? _save : null,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasImage) ...[
              AspectRatio(
                aspectRatio: 4 / 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(widget.post.selectedFile!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
