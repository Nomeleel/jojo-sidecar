import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CleanController {
  final StreamController<List<String>> streamController = StreamController();
  late StreamSubscription<String> scanSubscription;
  // TODO(Nomeleel): 开始 暂停 取消 结束
  final ValueNotifier<bool> scanProgressStatus = ValueNotifier<bool>(false);
  final ValueNotifier<double> scanProgress = ValueNotifier<double>(0);
  final List<String> scannedList = <String>[];
  final TextEditingController scanDirTextController = TextEditingController();

  final RegExp scanRegExp = RegExp('/(build|node_modules)\$');

  void scan() {
    _clear();
    scanProgressStatus.value = true;
    scanSubscription = _scanWithProcess(scanDirTextController.text).listen(
      (e) => streamController.add(scannedList..add(e)),
    );
    scanSubscription.onDone(() => scanProgressStatus.value = false);
  }

  Stream<String> _scanWithProcess(String directoryPath, [double begin = 0, double end = 1]) async* {
    final directoryList = Directory(directoryPath).listSync();
    final rangeProcess = RangeProgress(begin, end, directoryList.length);
    for (FileSystemEntity item in directoryList) {
      final String entityPath = item.path;
      if (await FileSystemEntity.isDirectory(entityPath)) {
        if (scanRegExp.stringMatch(entityPath)?.isNotEmpty ?? false) {
          yield entityPath;
        } else {
          yield* _scanWithProcess(entityPath, rangeProcess.start, rangeProcess.expect);
        }
      }
      scanProgress.value = rangeProcess.currentDone();
    }
  }

  void scanCanel() {
    scanSubscription.cancel();
    scanProgressStatus.value = false;
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

class RangeProgress {
  RangeProgress(this.begin, this.end, this.count);

  final double begin;
  final double end;
  final int count;

  int index = 0;

  double get start => _progress(index);
  double get expect => _progress(index + 1);
  double currentDone() => _progress(++index);
  double _progress(int current) => double.parse((begin + (end - begin) * (current / count)).toStringAsFixed(4));
}
