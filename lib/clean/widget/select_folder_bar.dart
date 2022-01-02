import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';

class SelectFolderBar extends StatelessWidget {
  SelectFolderBar({Key? key, required this.folderPath}) : super(key: key);

  final ValueNotifier<String> folderPath;
  final ValueNotifier<bool> _dragging = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => _dragging.value = true,
      onDragExited: (_) => _dragging.value = false,
      onDragDone: (dropDoneDetails) {
        final filePath = dropDoneDetails.files.first.path;
        folderPath.value = FileSystemEntity.isDirectorySync(filePath) ? filePath : FileSystemEntity.parentOf(filePath);
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: _dragging,
        builder: (context, dragging, staticChild) {
          Widget child = Container(
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: _dragging.value ? Colors.blue.withOpacity(0.4) : Colors.black26,
            ),
            child: _dragging.value ? const Center(child: Text('Drop Here')) : staticChild,
          );
          if (!_dragging.value) child = GestureDetector(onTap: _pickFolder, child: child);

          return child;
        },
        child: ValueListenableBuilder<String>(
          valueListenable: folderPath,
          builder: (context, path, child) {
            return Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Text(
                path.isEmpty ? 'pick or drop directory' : path,
              ),
            );
          },
        ),
      ),
    );
  }

  void _pickFolder() async {
    final directoryPath = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Pick Folder');
    if (directoryPath?.isNotEmpty ?? false) {
      folderPath.value = directoryPath!;
    }
  }
}
