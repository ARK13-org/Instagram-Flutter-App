import 'package:flutter/material.dart';
import 'package:instagram_ui/api/dart_api.dart';
import 'package:instagram_ui/api/session.dart';
import 'package:instagram_ui/widgets/brand.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _url = TextEditingController();
  final _caption = TextEditingController();
  bool _busy = false;

  bool get _validUrl {
    final u = Uri.tryParse(_url.text.trim());
    return u != null &&
        (u.scheme == 'http' || u.scheme == 'https') &&
        u.host.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _url.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _url.dispose();
    _caption.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await createPost(_url.text, _caption.text);
      Session.instance.bump();
      if (!mounted) return;
      showSnack(context, 'Posted!');
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
          'New post',
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
                aspectRatio: 1,
                child: _validUrl
                    ? Image.network(
                        _url.text.trim(),
                        fit: BoxFit.cover,
                        loadingBuilder: (c, child, p) => p == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (c, e, s) => _placeholder(
                          cs,
                          Icons.broken_image_outlined,
                          'Couldn’t load that image',
                        ),
                      )
                    : _placeholder(
                        cs,
                        Icons.add_photo_alternate_outlined,
                        'Paste an image link to preview it',
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: fieldDecoration(
                context,
                label: 'Image URL',
                hint: 'https://…',
                icon: Icons.link_rounded,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _caption,
              minLines: 3,
              maxLines: 8,
              maxLength: 2200,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDecoration(context, label: 'Write a caption…'),
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: 'Share',
              icon: Icons.send_rounded,
              loading: _busy,
              onPressed: _validUrl ? _share : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs, IconData icon, String text) {
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: cs.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
