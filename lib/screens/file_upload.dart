import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'dart:developer';
import 'package:flutter/services.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  Response? response;
  var dio = Dio();
  File? _storedFile;
  var filename = null;
  var emailTo = null;
  var emailFrom = null;
  var fileuuid = null;
  final _form = GlobalKey<FormState>();

  void _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    PlatformFile? file = result.files.first;
    filename = file.name;
    if (file.size > 104857600) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File should be less than 100 mb')));
      file = null;
      return;
    }
    log((file.size).toString());
    setState(() {
      _storedFile = File(result.files.single.path!);
    });

    log(_storedFile!.path);
  }

  _saveForm() async {
    if (_form.currentState == null) return;
    final isvalid = _form.currentState!.validate();
    log(isvalid.toString());
    if (!isvalid) return;
    _form.currentState!.save();
    if (fileuuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a file first')));
      return;
    }
    try {
      response = await dio.post(
          'https://mihir-fileshare.herokuapp.com/api/v1/files/send',
          data: {
            'uuid': fileuuid.toString(),
            'emailFrom': emailFrom.toString(),
            'emailTo': emailTo.toString()
          });
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
    log(response.toString());
  }

  @override
  void dispose() {
    _recieverFocusNode.dispose();
    super.dispose();
  }

  final _recieverFocusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 40, right: 40, top: 20),
            child: Text(
                'Upload and share Files upto 100 mb instantly with file share'),
          ),
          OutlinedButton(
              onPressed: () {
                _pickFiles();
              },
              child: const Text('Pick a file')),
          Container(
            alignment: Alignment.center,
            child: _storedFile != null
                ? Text(filename)
                : const Text('No file Selected'),
          ),
          OutlinedButton(
              onPressed: () async {
                if (_storedFile != null) {
                  var formData = FormData.fromMap({
                    'uploadedFile':
                        await MultipartFile.fromFile(_storedFile!.path)
                  });
                  try {
                    response = await dio.post(
                        'https://mihir-fileshare.herokuapp.com/api/v1/files',
                        data: formData);
                    log((response!.statusCode).toString());
                    log((response!.data['file']).toString());
                    fileuuid = response!.data['fileuuid'];
                  } catch (errror) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errror.toString())));
                  }
                  setState(() {});
                }
              },
              child: const Text('Upload file')),
          if (response != null)
            InkWell(
              splashColor: Colors.lightBlue,
              onLongPress: () {
                Clipboard.setData(ClipboardData(
                        text: (response!.data['file']).toString()))
                    .then((value) => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied'))));
              },
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).primaryColor, width: 3),
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                child: InkWell(
                  child: Row(
                    children: [
                      Flexible(
                        flex: 2,
                        child: SelectableText(
                            (response!.data['file']).toString(),
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Icon(Icons.copy)
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Form(
                key: _form,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Sender\'s Email address'),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          bool emailValid = RegExp(
                                  r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
                              .hasMatch(value!);
                          if (!emailValid) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          FocusScope.of(context)
                              .requestFocus(_recieverFocusNode);
                        },
                        onSaved: (value) => emailFrom = value,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Receiver\'s Email address'),
                        textInputAction: TextInputAction.next,
                        focusNode: _recieverFocusNode,
                        validator: (value) {
                          bool emailValid = RegExp(
                                  r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$')
                              .hasMatch(value!);
                          if (!emailValid) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                        onSaved: (value) => emailTo = value,
                      ),
                      Container(
                        width: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border:
                              Border.all(color: Colors.blueAccent, width: 3),
                        ),
                        margin: EdgeInsets.all(15),
                        child: TextButton(
                            onPressed: () => _saveForm(),
                            child: Text(
                              'Send Link',
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 18),
                            )),
                      )
                    ],
                  ),
                )),
          )
        ],
      ),
    );
  }
}
