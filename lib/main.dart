import 'package:material_ui/material_ui.dart';
import 'models/books.dart';
import 'services/epub_parser.dart';
import 'dart:async';
import 'dart:io';
import 'services/library_store.dart';
import 'screens/reader_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override 
  Widget build(BuildContext context) {
    return const MaterialApp( 
      title: 'Library',
      home: LibraryPage(),
    );
  }
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final store = LibraryStore('C:/Users/LUDWIG/epub');
  final List<Book> books = [];
  final Set<String> knownPaths = {};
  Timer? timer;

  @override
  void initState() {
    super.initState();
    store.load();
    scanFolder();
    timer = Timer.periodic(const Duration(seconds: 10), (_) => scanFolder());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
  

  void scanFolder() {
    final dir = Directory('C:/Users/LUDWIG/epub');
    if (!dir.existsSync()) return;

    final epubFiles = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.epub'));

    final newBooks = <Book>[];
    for (final file in epubFiles) {
      if (knownPaths.contains(file.path)) continue;

      final book = readEpub(file.path);
      if (book != null) {
        book.finished = store.isFinished(book.path);
        newBooks.add(book);
        knownPaths.add(file.path);
      }
    }
       final removed =
        books.where((b) => !File(b.path).existsSync()).toList();

    if (newBooks.isNotEmpty || removed.isNotEmpty) {
      setState(() {
        books.removeWhere((b) => removed.contains(b));
        knownPaths.removeAll(removed.map((b) => b.path));
        books.addAll(newBooks);
      });
    }
  }
    void toggleFinished(Book b) {
    setState(() {
      b.finished = !b.finished;
    });
    store.setFinished(b.path, b.finished);
    }
  


   @override
  Widget build(BuildContext context) {
    final reading = books.where((b) => !b.finished).toList();
    final finished = books.where((b) => b.finished).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Library'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Library (${reading.length})'),
              Tab(text: 'Finished (${finished.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            buildGrid(reading),
            buildGrid(finished),
          ],
        ),
      ),
    );
  }

  Widget buildGrid(List<Book> list) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final b = list[index];
        
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReaderPage(book: b)),
          ),
          onLongPress: () => toggleFinished(b),
          child: Card(
            child: Column(
              children: [
                Expanded(
                  child: b.cover != null
                      ? Image.memory(b.cover!,
                          fit: BoxFit.cover, width: double.infinity)
                      : const Icon(Icons.book, size: 64),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(b.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}