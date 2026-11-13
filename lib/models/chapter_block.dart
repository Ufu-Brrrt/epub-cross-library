import 'dart:typed_data';

class ChapterBlock {
  final String? text;
  final Uint8List? image;

  ChapterBlock.text(this.text) : image = null;
  ChapterBlock.image(this.image) : text = null;
}