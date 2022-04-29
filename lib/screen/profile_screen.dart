import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final TextEditingController _textFieldControllerEmail =
      TextEditingController();
  final TextEditingController _textFieldControllerName =
      TextEditingController();
  List<UploadTask> uploadedTasks = [];

  List<File> selectedFiles = [];

  uploadFileToStorage(File file) {
    UploadTask task =
        _firebaseStorage.ref().child("profil/${"profil"}").putFile(file);
    return task;
  }

  writeImageUrlToFireStore(imageUrl) {
    var name = _firebaseFirestore.collection("profil").doc("name").get();
    print(name);
    _firebaseFirestore
        .collection("profil")
        .doc("profil")
        .update({"url": imageUrl}).whenComplete(
            () => print("$imageUrl profil fotografı kaydedildi"));
  }

  saveImageUrlToFirebase(UploadTask task) {
    task.snapshotEvents.listen((snapShot) {
      if (snapShot.state == TaskState.success) {
        snapShot.ref
            .getDownloadURL()
            .then((imageUrl) => writeImageUrlToFireStore(imageUrl));
      }
    });
  }

  Future selectFileToUpload() async {
    try {
      FilePickerResult result = await FilePicker.platform
          .pickFiles(allowMultiple: true, type: FileType.image);

      if (result != null) {
        selectedFiles.clear();

        result.files.forEach((selectedFile) {
          File file = File(selectedFile.path);
          selectedFiles.add(file);
        });

        selectedFiles.forEach((file) {
          final UploadTask task = uploadFileToStorage(file);
          saveImageUrlToFirebase(task);

          setState(() {
            uploadedTasks.add(task);
          });
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(8),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firebaseFirestore.collection("profil").snapshots(),
          builder: (context, snapshot) {
            return snapshot.hasError
                ? Center(
                    child: Text("İnternet bağlantınızı kontrol edin"),
                  )
                : snapshot.data?.size! != null
                    ? GridView.count(
                        crossAxisCount: 1,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1,
                        children: snapshot.data!.docs
                            .map(
                              (e) => Column(children: [
                                Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        child: GestureDetector(
                                          child: PopupMenuButton<String>(
                                            onSelected: handleClick,
                                            child: CircleAvatar(
                                              backgroundImage:
                                                  NetworkImage(e.get("url")),
                                              radius: 100,
                                            ),
                                            itemBuilder:
                                                (BuildContext context) {
                                              return {'Degiştir'}
                                                  .map((String choice) {
                                                return PopupMenuItem<String>(
                                                  value: e.get("id").toString(),
                                                  child: Text(choice),
                                                );
                                              }).toList();
                                            },
                                          ),
                                        ),
                                      ),
                                    ]),
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.only(top: 50),
                                        child: Column(children: [
                                          Text(
                                            "AD SOYAD :",
                                            style: DefaultTextStyle.of(context)
                                                .style
                                                .apply(
                                                    fontSizeFactor: 1.5,
                                                    color: Colors.red),
                                          ),
                                          Text(
                                            "E-Mail :",
                                            style: DefaultTextStyle.of(context)
                                                .style
                                                .apply(
                                                    fontSizeFactor: 1.5,
                                                    color: Colors.red),
                                          )
                                        ]),
                                      ),
                                      Container(
                                        padding: EdgeInsets.only(top: 50),
                                        child: Column(
                                          children: [
                                            Text(
                                              e.get("name"),
                                              style:
                                                  DefaultTextStyle.of(context)
                                                      .style
                                                      .apply(
                                                          fontSizeFactor: 1.3,
                                                          color: Colors.black),
                                            ),
                                            Text(
                                              e.get("email"),
                                              style:
                                                  DefaultTextStyle.of(context)
                                                      .style
                                                      .apply(
                                                          fontSizeFactor: 1.3,
                                                          color: Colors.black),
                                            )
                                          ],
                                        ),
                                      ),
                                    ])
                              ]),
                            )
                            .toList(),
                      )
                    : Container(
                        child: Center(
                        child: Text("Yükleniyor..."),
                      ));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _editUser();
        },
        child: Icon(Icons.save_rounded),
      ),
    );
  }

  handleClick(String value) {
    selectFileToUpload();
  }

  Future<void> _editUser() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bilgilerinizi Güncelleyin'),
          content: Container(
            height: 100,
            child: Column(
              children: [
                TextField(
                  maxLines: 1,
                  controller: _textFieldControllerName,
                  decoration: const InputDecoration(hintText: 'Ad Soyad Girin'),
                ),
                TextField(
                  maxLines: 1,
                  controller: _textFieldControllerEmail,
                  decoration: const InputDecoration(hintText: 'E-Mail Girin'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Güncelle'),
              onPressed: () {
                Navigator.of(context).pop();
                (_textFieldControllerName.text.length > 1 &&
                        _textFieldControllerEmail.text.length > 1)
                    ? _updateUser(_textFieldControllerName.text,
                        _textFieldControllerEmail.text)
                    : null;
              },
            ),
          ],
        );
      },
    );
  }

  void _updateUser(String name, String email) {
    _firebaseFirestore
        .collection("profil")
        .doc("profil")
        .update({"name": name, "email": email});
    _textFieldControllerName.clear();
    _textFieldControllerEmail.clear();
  }
}
