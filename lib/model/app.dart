class App {
  final List<String>? devFolderName;

  App.fromMap(Map map) : devFolderName = (map['devFolderName'] as List?)?.map<String>((e) => e.toString()).toList();
}
