import 'dart:async';
import 'dart:developer';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({Key? key}) : super(key: key);

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  Response? response;
  var dio = Dio();
  final _form = GlobalKey<FormState>();
  var isloading = false;
  var fileLink;
  var fileName;
  var fileSize;
  var downloadLink;
  bool isDownloading = false;
  String progress = '0';
  Future<String?> getDownloadPath() async {
    Directory? directory;
    try {
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      }
    } catch (err) {
      log("Cannot get download folder path");
    }
    return directory?.path;
  }

  _downloadFile() async {
    log(downloadLink);
    try {
      var path = await getDownloadPath();
      path = path! + '/$fileName';
      setState(() {
        isDownloading = true;
      });
      await dio.download(
        downloadLink,
        path,
        onReceiveProgress: (rcv, total) {
          log('received: ${rcv.toStringAsFixed(0)} out of total: ${total.toStringAsFixed(0)}');

          setState(() {
            progress = ((rcv / total) * 100).toStringAsFixed(0);
          });

          if (progress == '100') {
            setState(() {
              isDownloading = false;
            });
          } else if (double.parse(progress) < 100) {}
        },
        deleteOnError: true,
      ).then((_) {
        setState(() {
          if (progress == '100') {
            isDownloading = false;
          }
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download completed,Check Downloads Folder')));
      progress = '0';
    } catch (error) {
      if (response!.statusCode == 404) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('File doesnt exist')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Server Error')));
      }

      log(error.toString());
      setState(() {
        isDownloading = false;
      });
    }
  }

  _getFileDetails() async {
    _form.currentState!.save();
    if (fileLink == null) return;
    try {
      setState(() {
        isloading = true;
      });
      response = await dio.get(fileLink);
      fileName = (response!.data['filename']).toString();
      fileSize = (response!.data['filesize']).toString();
      downloadLink = (response!.data['downloadlink']).toString();
      setState(() {
        isloading = false;
      });
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return isloading
        ? const Center(child: CircularProgressIndicator.adaptive())
        : SingleChildScrollView(
            child: Column(
              children: [
                Form(
                    key: _form,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'Enter File link here'),
                              onSaved: (value) {
                                fileLink = value;
                              },
                            ),
                          ),
                          IconButton(
                              onPressed: () => _getFileDetails(),
                              icon: const Icon(Icons.search_outlined))
                        ],
                      ),
                    )),
                if (response != null)
                  Column(
                    children: [
                     const  Text('File Details are as follows:'),
                      Text('FileName: $fileName'),
                      Text('FileSize: $fileSize bytes'),
                      OutlinedButton(
                          onPressed: () {
                            _downloadFile();
                          },
                          child:const  Text('Download file now'))
                    ],
                  ),
                if (isDownloading == true) Text('Downloading : ${progress}%'),
              ],
            ),
          );
  }
}
