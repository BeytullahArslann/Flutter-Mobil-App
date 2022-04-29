import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HesCodeScreen extends StatefulWidget {
  @override
  _HesCodeScreenState createState() => _HesCodeScreenState();
}

class _HesCodeScreenState extends State<HesCodeScreen> {
  FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final TextEditingController _textFieldControllerHesCode =
      TextEditingController();
  final TextEditingController _textFieldControllerDate =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          secondary: Colors.green,
        ),
      ),
      home: Scaffold(
        body: StreamBuilder(
            stream: _firebaseFirestore.collection('hescode').snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              return ListView(
                children: snapshot.data!.docs
                    .map(
                      (e) => Container(
                          child: Column(children: [
                        QrImage(
                          data: e.get("hescode").toString().toUpperCase(),
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                        Text(
                          e.get("hescode").toString().toUpperCase(),
                          style: DefaultTextStyle.of(context)
                              .style
                              .apply(fontSizeFactor: 3.0, color: Colors.red),
                        ),
                        Text(
                          e.get("date"),
                          style: DefaultTextStyle.of(context)
                              .style
                              .apply(fontSizeFactor: 2.0, color: Colors.black),
                        ),
                      ])),
                    )
                    .toList(),
              );
            }),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _editHes();
          },
          child: Icon(Icons.medical_services_rounded),
        ),
      ),
    );
  }

  Future<void> _editHes() async {
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
                  controller: _textFieldControllerHesCode,
                  decoration:
                      const InputDecoration(hintText: 'Hes Kodunuzu Girin'),
                ),
                TextField(
                  maxLines: 1,
                  controller: _textFieldControllerDate,
                  decoration: const InputDecoration(
                      hintText: 'Son Geçerlilik Tarihini Girin'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Güncelle'),
              onPressed: () {
                Navigator.of(context).pop();
                _textFieldControllerHesCode.text.length > 1
                    ? _updateHes(_textFieldControllerHesCode.text,
                        _textFieldControllerDate.text)
                    : null;
              },
            ),
          ],
        );
      },
    );
  }

  void _updateHes(String hescode, String date) {
    var id = DateTime.now().millisecondsSinceEpoch;
    _firebaseFirestore
        .collection("hescode")
        .doc("hescode")
        .update({"hescode": hescode, "date": date});

    _textFieldControllerHesCode.clear();
    _textFieldControllerDate.clear();
  }
}
