
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'dart:convert';
import '../models/books.dart';
import 'dart:typed_data';

Book? readEpub(String path) {
  
  final file = File(path);
  final bytes = file.readAsBytesSync();
  
  final archive = ZipDecoder().decodeBytes(bytes);
  final entry = archive.findFile('META-INF/container.xml');

  if (entry == null) {
    print('container.xml not found');
    return null;
  }
  
  final text = utf8.decode(entry.content as List<int>);
  final doc = XmlDocument.parse(text);
  final rootfile = doc.findAllElements('rootfile').first;

  final opfPath = rootfile.getAttribute('full-path');

  if (opfPath == null) {
    print('No .opf path found');
    return null;

  }
  
  final opfEntry = archive.findFile(opfPath);
  if (opfEntry == null) {
    print('.opf file not found');
    return null;
  }

  final opfText = utf8.decode(opfEntry.content as List<int>);
  final opfDoc = XmlDocument.parse(opfText);

  final title = opfDoc.findAllElements('dc:title').firstOrNull?.innerText ?? 'Unknown Title';
  final author = opfDoc.findAllElements('dc:creator').firstOrNull?.innerText ?? 'Unknown Author';
  final cover = findCover(archive, opfDoc, opfPath);

  return Book(title: title, author: author, path: path, cover: cover);
  
}

Uint8List? findCover(Archive archive, XmlDocument opfDoc, String opfPath) {
  final items = opfDoc.findAllElements('item');
  XmlElement? coverItem;

  for (final item in items) {
    final props = item.getAttribute('properties') ?? '';
    if (props.split(' ').contains('cover-image')) {
      coverItem = item;
      break;
    }
  }
  if (coverItem == null) {
    final meta = opfDoc.findAllElements('meta').where((m) => m.getAttribute('name') == 'cover').firstOrNull;
    final coverId = meta?.getAttribute('content');
    if (coverId != null) {
      coverItem = items.where((i) => i.getAttribute('id') ==coverId).firstOrNull;

    }
  }
  final href = coverItem?.getAttribute('href'); 
  if (href == null) return null;

  final slash = opfPath.lastIndexOf('/');
  final baseDir = slash == -1 ? '' : opfPath.substring(0, slash + 1);
  final coverPath = baseDir + Uri.decodeFull(href);

  final entry = archive.findFile(coverPath);
  if (entry == null) return null;
  return Uint8List.fromList(entry.content as List<int>);
}

