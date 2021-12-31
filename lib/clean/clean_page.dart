import 'package:flutter/material.dart';

import 'clean_controller.dart';

class CleanPage extends StatefulWidget {
  const CleanPage({Key? key}) : super(key: key);

  @override
  State<CleanPage> createState() => _CleanPageState();
}

class _CleanPageState extends State<CleanPage> {
  final CleanController _controller = CleanController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.purple,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller.scanDirTextController,
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _controller.scanProgressStatus,
                      builder: (context, active, child) {
                        return IconButton(
                          icon: Icon(active ? Icons.clear : Icons.search),
                          onPressed: active ? _controller.scanCanel : _controller.scan,
                        );
                      },
                    ),
                  ],
                ),
                ValueListenableBuilder<List<String>>(
                  valueListenable: _controller.cleanFolderNameList,
                  builder: (context, folderNameList, child) {
                    return Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      children: folderNameList.map<Widget>((e) {
                        return InputChip(
                          label: Text(e),
                          onDeleted: () => _controller.delCleanFolderName(e),
                        );
                      }).toList()
                        ..add(
                          SizedBox(
                            width: 77,
                            height: 20,
                            child: TextField(
                              onSubmitted: (text) {
                                _controller.addCleanFolderName(text);
                              },
                            ),
                          ),
                        ),
                    );
                  },
                ),
                FutureBuilder<List<String>>(
                  future: _controller.getSuggestCleanFolderName(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    return Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      children: snapshot.data!.map((e) {
                        return InputChip(
                          label: Text(e),
                          onPressed: () => _controller.addCleanFolderName(e),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: _controller.scanProgress,
            builder: (context, progress, child) {
              return LinearProgressIndicator(
                value: progress,
                color: ColorTween(begin: Colors.blue).transform(progress),
                backgroundColor: Colors.transparent,
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: _controller.streamController.stream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return ListView.separated(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final path = snapshot.data![index];
                    return ListTile(
                      title: Text(_controller.getSimplePath(path)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.folder),
                            onPressed: () => _controller.lunchFolder(path),
                          ),
                          const SizedBox(width: 15),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteFolder(index: index, path: path),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(indent: 7, endIndent: 7),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _deleteFolder({int? index, String? path}) async {
    final result = await showDialog<bool>(
      routeSettings: const RouteSettings(name: 'clean_page_remove_folder_dialog'),
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确定删除该文件夹吗？'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.maybeOf(context)?.pop(false),
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () => Navigator.maybeOf(context)?.pop(true),
            ),
          ],
        );
      },
    );

    if (result ?? false) {
      _controller.deleteFolder(index: index, path: path);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
