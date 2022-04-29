import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditTodoScreen extends StatefulWidget {
  final String id;
  const EditTodoScreen({Key? key, required this.id}) : super(key: key);

  @override
  _EditTodoScreenState createState() => _EditTodoScreenState();
}

class _EditTodoScreenState extends State<EditTodoScreen> {
  final TextEditingController _textFieldController = TextEditingController();
  final TextEditingController _textFieldControllerHeader =
      TextEditingController();
  FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Todo Düzenle"),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => saveTodo(),
          tooltip: 'Todo Ekle',
          child: Icon(Icons.save_rounded)),
      body: StreamBuilder(
          stream: _firebaseFirestore.collection('Todos').snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            return ListView(
              children: snapshot.data!.docs
                  .where(
                      (element) => element.get("id") == int.tryParse(widget.id))
                  .map(
                    (e) => Container(
                      padding: EdgeInsets.all(25.0),
                      child: Column(
                        children: [
                          TextField(
                            maxLines: 1,
                            controller: _textFieldControllerHeader,
                            decoration: InputDecoration(
                                hintText: e.get("Todo Head").toString()),
                            onTap: () {
                              _textFieldControllerHeader.text.length < 1
                                  ? _textFieldControllerHeader.text =
                                      e.get("Todo Head")
                                  : null;
                            },
                          ),
                          TextField(
                            minLines: 1,
                            maxLines: 10,
                            controller: _textFieldController,
                            decoration:
                                InputDecoration(hintText: e.get("Todo Desc")),
                            onTap: () {
                              _textFieldController.text.length < 1
                                  ? _textFieldController.text =
                                      e.get("Todo Desc")
                                  : null;
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            );
          }),
    );
  }

  saveTodo() {
    print(_textFieldController.text);
    _firebaseFirestore.collection("Todos").doc(widget.id.toString()).update({
      "Todo Head": _textFieldControllerHeader.text,
      "Todo Desc": _textFieldController.text
    });
  }
}
