import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CleanController {
  final StreamController<List<String>> streamController = StreamController();
  late StreamSubscription<String> scanSubscription;
  final List<String> scannedList = <String>[];
  final TextEditingController scanDirTextController = TextEditingController();

  final RegExp scanRegExp = RegExp('/(build|node_modules)\$');

  void scan() {
    _clear();
    scanSubscription = _scan(scanDirTextController.text).listen((e) => streamController.add(scannedList..add(e)));
    scanSubscription.onDone(() {
      // TODO: imp
    });
  }

  Stream<String> _scan(String directoryPath) async* {
    final directoryStream = Directory(directoryPath).list();
    await for (FileSystemEntity item in directoryStream) {
      final String entityPath = item.path;
      if (FileSystemEntity.isDirectorySync(entityPath)) {
        if (scanRegExp.stringMatch(entityPath)?.isNotEmpty ?? false) {
          yield entityPath;
        } else {
          yield* _scan(entityPath);
        }
      }
    }
  }

  void scanCanel() {
    scanSubscription.cancel();
  }

  void _clear() {
    streamController.add(scannedList..clear());
  }

  Future<bool> deleteFolder({int? index, String? path}) async {
    if (path?.isNotEmpty ?? false) {
      try {
        await Directory(path!).delete(recursive: true);
        index ??= scannedList.indexWhere((e) => e == path);
        streamController.add(scannedList..removeAt(index));
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  Future<bool> lunchFolder(String path) {
    return launch(Uri.directory(path).toString());
  }

  String getSimplePath(String path) {
    return path.substring(scanDirTextController.text.length);
  }

  void dispose() {
    streamController.close();
    scanSubscription.cancel();
    scanDirTextController.dispose();
  }
}
