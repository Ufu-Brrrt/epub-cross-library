
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'dart:convert';

import '../models/books.dart';

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

  return Book(title: title, author: author, path: path);
}


