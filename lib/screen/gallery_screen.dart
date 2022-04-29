import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

// https://www.youtube.com/watch?v=pfKXrmdrNaU
class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  List<UploadTask> uploadedTasks = [];

  List<File> selectedFiles = [];

  uploadFileToStorage(File file) {
    UploadTask task = _firebaseStorage
        .ref()
        .child("images/${DateTime.now().toString()}")
        .putFile(file);
    return task;
  }

  writeImageUrlToFireStore(imageUrl) {
    var id = DateTime.now().millisecondsSinceEpoch;
    _firebaseFirestore
        .collection("images")
        .doc(id.toString())
        .set({"id": id, "url": imageUrl}).whenComplete(
            () => print("$imageUrl görsel kaydedildi"));
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
    var id = DateTime.now().millisecondsSinceEpoch;
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
          stream: _firebaseFirestore.collection("images").snapshots(),
          builder: (context, snapshot) {
            return snapshot.hasError
                ? Center(
                    child: Text("İnternet bağlantınızı kontrol edin"),
                  )
                : snapshot.data?.size! != null
                    ? GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1,
                        children: snapshot.data!.docs
                            .map(
                              (e) => Container(
                                  child: GestureDetector(
                                child: PopupMenuButton<String>(
                                  onSelected: handleClick,
                                  child: Image.network(e.get("url")),
                                  itemBuilder: (BuildContext context) {
                                    return {'Sil'}.map((String choice) {
                                      return PopupMenuItem<String>(
                                        value: e.get("id").toString(),
                                        child: Text(choice),
                                      );
                                    }).toList();
                                  },
                                ),
                              )),
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
          selectFileToUpload();
        },
        child: Icon(Icons.add_a_photo_rounded),
      ),
    );
  }

  handleClick(String value) {
    print(value);
    _firebaseFirestore.collection("images").doc(value).delete();
  }
}
