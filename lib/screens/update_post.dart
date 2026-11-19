import 'package:flutter/material.dart';
import 'package:instagram_ui/api/dart_api.dart';
import 'package:instagram_ui/models/post_model.dart';
import 'package:instagram_ui/widgets/brand.dart';

class UpdatePostScreen extends StatefulWidget {
  const UpdatePostScreen({super.key, required this.post});
  final Posts post;

  @override
  State<UpdatePostScreen> createState() => _UpdatePostScreenState();
}

class _UpdatePostScreenState extends State<UpdatePostScreen> {
  late final TextEditingController _caption = TextEditingController(
    text: widget.post.caption,
  );
  bool _busy = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await updatePost(widget.post.id, _caption.text.trim());
      if (!mounted) return;
      showSnack(context, 'Post updated');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit post',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 1.4,
                child: Image.network(
                  widget.post.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: cs.surfaceContainerHighest,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined, size: 40),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _caption,
              minLines: 4,
              maxLines: 10,
              maxLength: 2200,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDecoration(context, label: 'Caption'),
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: 'Save changes',
              loading: _busy,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
