import 'package:material_ui/material_ui.dart';
import 'models/books.dart';

import 'services/epub_parser.dart';

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

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final book = readEpub('C:/Users/LUDWIG/epub/Naval Admiral.epub');
    final books = <Book>[if (book != null) book];

    return Scaffold(
      appBar: AppBar(title: const Text('My Library')),
      body: ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          final b = books[index];
          return ListTile(
            leading: const Icon(Icons.book), 
            title: Text(b.title),
            subtitle: Text(b.author),
          );
        }
      ),
    );
  }
}