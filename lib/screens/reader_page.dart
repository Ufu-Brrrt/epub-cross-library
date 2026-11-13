import 'package:material_ui/material_ui.dart';
import '../models/chapter_block.dart';
import '../models/books.dart';
import '../services/epub_parser.dart';

class ReaderPage extends StatefulWidget {
  final Book book;
  const ReaderPage({super.key, required this.book});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
List<List<ChapterBlock>> chapters = [];
  int current = 0;

  @override
  void initState() {
    super.initState();
    chapters = readChapters(widget.book.path);
  }

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: const Center(child: Text('Could not read this book')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: SingleChildScrollView(
                  key: ValueKey(current),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final block in chapters[current])
                        if (block.image != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Image.memory(
                              block.image!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              block.text!,
                              style: const TextStyle(fontSize: 18, height: 1.6),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed:
                      current > 0 ? () => setState(() => current--) : null,
                  child: const Text('Previous'),
                ),
                Text('${current + 1} / ${chapters.length}'),
                TextButton(
                  onPressed: current < chapters.length - 1
                      ? () => setState(() => current++)
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}