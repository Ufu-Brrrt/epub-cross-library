import 'dart:convert';
import 'dart:io';

class LibraryStore {
  final File _file;
  Map<String, dynamic> _data = {};

  LibraryStore(String folder) : _file = File('$folder/.library_state.json');

  String _key(String path) => path.split(RegExp(r'[\\/]')).last;

  void load() {
    if (!_file.existsSync()) return;
    try {
      _data = jsonDecode(_file.readAsStringSync()) as Map<String, dynamic>;
    } catch (_) {
      _data = {};
    }
  }

  bool isFinished(String path) => _data[_key(path)]?['finished'] == true;

  void setFinished(String path, bool value) {
    _data[_key(path)] = {'finished': value};
    _file.writeAsStringSync(jsonEncode(_data));
  }
}