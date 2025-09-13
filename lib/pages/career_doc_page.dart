import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

import '../main.dart'; // lấy portName

class CareerDocsPage extends StatefulWidget {
  final String careerId;
  const CareerDocsPage({super.key, required this.careerId});

  @override
  State<CareerDocsPage> createState() => _CareerDocsPageState();
}

class _CareerDocsPageState extends State<CareerDocsPage> {
  ReceivePort _port = ReceivePort();
  String? _lastFilePath;

  /// Map lưu tiến trình: taskId -> progress (%)
  Map<String, int> _progressMap = {};
  /// Map taskId -> filePath (để mở đúng file)
  Map<String, String> _taskFileMap = {};

  @override
  void initState() {
    super.initState();

    IsolateNameServer.removePortNameMapping(portName);
    IsolateNameServer.registerPortWithName(_port.sendPort, portName);

    _port.listen((dynamic data) async {
      final String taskId = data[0];
      final int rawStatus = data[1];
      final int progress = data[2];

      final taskStatus = DownloadTaskStatus.fromInt(rawStatus);

      setState(() {
        _progressMap[taskId] = progress;   // update %
      });

      if (taskStatus == DownloadTaskStatus.complete) {
        final filePath = _taskFileMap[taskId];
        if (filePath != null) {
          await OpenFile.open(filePath);
        }
      }
    });
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping(portName);
    super.dispose();
  }

  Future<void> _checkPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
  }

  Future<void> _downloadFile(
      BuildContext context, String url, String filename) async {
    await _checkPermission();

    Directory dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory())!;
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final filePath = "${dir.path}/$filename";

    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: dir.path,
      fileName: filename,
      showNotification: true,
      openFileFromNotification: true,
    );

    if (taskId != null) {
      _taskFileMap[taskId] = filePath;
      setState(() {
        _progressMap[taskId] = 0;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đang tải $filename...")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text("Tài liệu nghề")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("CareerBank")
            .doc(widget.careerId)
            .collection("Docs")
            .orderBy("updatedAt", descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Chưa có tài liệu nào"));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;

              final title = (data['title'] ?? '').toString();
              final desc = (data['description'] ?? '').toString();
              final type = (data['type'] ?? 'pdf').toString();
              final url = (data['url'] ?? '').toString();

              final ext = type == 'video' ? 'mp4' : 'pdf';
              final filename = "$title.$ext";

              // tìm taskId nào đang tải file này
              final taskId = _taskFileMap.keys.firstWhere(
                    (id) => _taskFileMap[id]?.endsWith(filename) ?? false,
                orElse: () => '',
              );

              final progress = taskId.isNotEmpty ? _progressMap[taskId] ?? 0 : null;

              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      type == 'video' ? Icons.video_library : Icons.picture_as_pdf,
                      color: primary,
                    ),
                    title: Text(title),
                    subtitle: Text(desc),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {
                        if (url.isNotEmpty) {
                          _downloadFile(context, url, filename);
                        }
                      },
                    ),
                  ),
                  if (progress != null && progress < 100)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: Colors.grey.shade300,
                            color: primary,
                          ),
                          const SizedBox(height: 4),
                          Text("Đang tải: $progress%"),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
