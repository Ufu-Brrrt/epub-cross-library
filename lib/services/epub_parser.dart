
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'dart:convert';
import '../models/books.dart';
import 'dart:typed_data';
import '../models/chapter_block.dart';

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

List<List<ChapterBlock>> readChapters(String path) {
  final archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());

  final container = archive.findFile('META-INF/container.xml');
  if (container == null) return [];
  final containerDoc =
      XmlDocument.parse(utf8.decode(container.content as List<int>));
  final opfPath = containerDoc
      .findAllElements('rootfile')
      .firstOrNull
      ?.getAttribute('full-path');
  if (opfPath == null) return [];

  final opfEntry = archive.findFile(opfPath);
  if (opfEntry == null) return [];
  final opfDoc =
      XmlDocument.parse(utf8.decode(opfEntry.content as List<int>));

  final hrefById = <String, String>{};
  for (final item in opfDoc.findAllElements('item')) {
    final id = item.getAttribute('id');
    final href = item.getAttribute('href');
    if (id != null && href != null) hrefById[id] = href;
  }

  final slash = opfPath.lastIndexOf('/');
  final baseDir = slash == -1 ? '' : opfPath.substring(0, slash + 1);

  const textTags = ['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'];
  final chapters = <List<ChapterBlock>>[];

  for (final ref in opfDoc.findAllElements('itemref')) {
    final href = hrefById[ref.getAttribute('idref')];
    if (href == null) continue;

    final chapterPath = baseDir + Uri.decodeFull(href);
    final entry = archive.findFile(chapterPath);
    if (entry == null) continue;

    try {
      final doc = XmlDocument.parse(utf8.decode(entry.content as List<int>));
      final body = doc.findAllElements('body').firstOrNull;
      if (body == null) continue;

      final blocks = <ChapterBlock>[];
      for (final e in body.descendants.whereType<XmlElement>()) {
        final tag = e.name.local;

        if (textTags.contains(tag)) {
          final t = e.innerText.trim();
          if (t.isNotEmpty) blocks.add(ChapterBlock.text(t));
        } else if (tag == 'img' || tag == 'image') {
          final src = e.getAttribute('src') ??
              e.getAttribute('xlink:href') ??
              e.getAttribute('href');
          if (src == null || src.startsWith('data:')) continue;

          final imgEntry = archive.findFile(resolvePath(chapterPath, src));
          if (imgEntry != null) {
            blocks.add(ChapterBlock.image(
                Uint8List.fromList(imgEntry.content as List<int>)));
          }
        }
      }

      if (blocks.isEmpty) {
        final t = body.innerText.trim();
        if (t.isNotEmpty) blocks.add(ChapterBlock.text(t));
      }
      if (blocks.isNotEmpty) chapters.add(blocks);
    } catch (_) {
      // skip a chapter that fails to parse
    }
  }
  return chapters;
}

String resolvePath(String chapterPath, String src) {
  final slash = chapterPath.lastIndexOf('/');
  final baseDir = slash == -1 ? '' : chapterPath.substring(0, slash + 1);
  final cleaned = Uri.decodeFull(src.split('#').first);

  final parts = <String>[];
  for (final p in (baseDir + cleaned).split('/')) {
    if (p == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (p != '.' && p.isNotEmpty) {
      parts.add(p);
    }
  }
  return parts.join('/');
}