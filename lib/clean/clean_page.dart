import 'package:flutter/material.dart';
import 'clean_controller.dart';
import 'widget/select_folder_bar.dart';

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
                    Expanded(child: SelectFolderBar(folderPath: _controller.scanFolderPath)),
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
                final folderDataSource = FolderDataSource(
                  _controller,
                  snapshot.data!.map((e) => FolderItem(e)).toList(),
                  delete: () async {
                    if (await _deleteConfirm()) {
                            folderDataSource._deleteSelect();
                          }
                  },
                );
                return SingleChildScrollView(
                  child: PaginatedDataTable(
                    columns: [
                      DataColumn(
                        label: const Text('Folder'),
                        onSort: (columnIndex, ascending) {},
                      ),
                      const DataColumn(label: Text('Action'))
                    ],
                    source: folderDataSource,
                    header: const Text('Scan Result:'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          if (await _deleteConfirm()) {
                            folderDataSource._deleteSelect();
                          }
                        },
                      ),
                    ],
                    onSelectAll: folderDataSource._onSelectAll,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _deleteConfirm() async {
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

    return result ?? false;
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}

class FolderItem {
  FolderItem(this.path);

  final String path;

  bool selected = false;
}

class FolderDataSource extends DataTableSource {
  FolderDataSource(
    this.controller,
    this.folderList, {
    this.delete,
  });

  final List<FolderItem> folderList;
  final CleanController controller;
  final Function? delete;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => folderList.length;

  @override
  int get selectedRowCount => folderList.where((e) => e.selected).length;

  @override
  DataRow? getRow(int index) {
    if (index >= folderList.length) return null;
    final FolderItem folderItem = folderList[index];
    return DataRow.byIndex(
      index: index,
      selected: folderItem.selected,
      onSelectChanged: (value) {
        folderItem.selected = value ?? false;
        notifyListeners();
      },
      cells: <DataCell>[
        DataCell(Text(folderItem.path)),
        DataCell(_actions(index, folderItem.path)),
      ],
    );
  }

  Widget _actions(int index, String path) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.folder),
          onPressed: () => controller.lunchFolder(path),
        ),
        const SizedBox(width: 15),
        if (delete != null)
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              delete()
              folderList.removeAt(index);
              notifyListeners();
            },
          ),
      ],
    );
  }

  void _onSelectAll(bool? value) {
    void onSelect(e) => e.selected = value ?? false;
    folderList.forEach(onSelect);
    notifyListeners();
  }

  void _deleteSelect() {
    folderList.removeWhere((e) => e.selected);
    notifyListeners();
  }

  // TODO(Nomeleel): Sort
}
