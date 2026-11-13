import 'dart:typed_data';



class Book {
    bool finished;
    
  final String title;
  final String author; 
  final String path;
  final Uint8List? cover;

  Book(
    {
    required this.title, 
    required this.author, 
    required this.path,
    this.cover,
    this.finished = false,
    }
  );

}
