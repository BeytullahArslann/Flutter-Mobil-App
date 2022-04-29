import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'edittodo_screen.dart';

FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

class Todo {
  Todo(
      {required this.id,
      required String this.header,
      required this.desc,
      required this.checked});
  final String id;
  final String header;
  final String desc;
  bool checked;
}

class TodoItem extends StatefulWidget {
  TodoItem({
    required this.todo,
    this.onTodoChanged,
    this.popupMenuButton,
  }) : super(key: ObjectKey(todo));
  final Todo todo;
  final onTodoChanged;
  final popupMenuButton;

  String get id => todo.id;

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem> {
  final todoState = new _TodoListState();

  TextStyle? _getTextStyle(bool checked) {
    if (!checked) return null;

    return TextStyle(
      color: Colors.black54,
      decoration: TextDecoration.lineThrough,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        widget.onTodoChanged(widget.todo);
      },
      leading: widget.todo.checked
          ? Icon(
              Icons.check_circle_outline,
              size: 40,
            )
          : Icon(
              Icons.radio_button_unchecked,
              size: 40,
            ),
      trailing: PopupMenuButton<String>(
        onSelected: handleClick,
        itemBuilder: (BuildContext context) {
          return {'Düzenle', 'Sil'}.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
      ),
      title: Center(child: Text(widget.todo.header)),
      subtitle: Center(
          child: Text(widget.todo.desc,
              style: _getTextStyle(widget.todo.checked))),
    );
  }

  void handleClick(String value) {
    switch (value) {
      case 'Düzenle':
        var route = new MaterialPageRoute(
            builder: (BuildContext context) =>
                new EditTodoScreen(id: widget.id));
        Navigator.of(context).push(route);
        break;
      case 'Sil':
        todoState._deleteTodo(widget.popupMenuButton(widget.todo));
        break;
    }
  }
}

final List<Todo> _todos = <Todo>[];
final List<Todo> _todosOk = <Todo>[];

class TodoList extends StatefulWidget {
  @override
  _TodoListState createState() => new _TodoListState();
}

class _TodoListState extends State<TodoList> {
  int selectedIndex = 0;
  final TextEditingController _textFieldController = TextEditingController();
  final TextEditingController _textFieldControllerHeader =
      TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () => _displayDialog(),
          tooltip: 'Todo Ekle',
          child: Icon(Icons.add_task_outlined)),
      bottomNavigationBar: BottomNavigationBar(
        //https://www.youtube.com/watch?v=kN9Yfd4fu04
        backgroundColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        selectedItemColor: Colors.white,
        currentIndex: selectedIndex,
        onTap: (index) => setState(() {
          selectedIndex = index;
        }),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            label: 'Yapılacaklar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.done, size: 28),
            label: 'Tamamlananlar',
          ),
        ],
      ),
      body: StreamBuilder(
          stream: _firebaseFirestore.collection('Todos').snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            return selectedIndex == 0
                ? ListView(
                    children: snapshot.data!.docs
                        .where((element) => element.get("Status") == false)
                        .map(
                          (e) => TodoItem(
                            todo: Todo(
                                id: e.get("id").toString(),
                                header: e.get("Todo Head"),
                                desc: e.get("Todo Desc"),
                                checked: e.get("Status")),
                            //todo: Todo(id: snapshot.data),
                            onTodoChanged: _completed,
                            popupMenuButton: _deleteTodo,
                          ),
                        )
                        .toList(),
                  )
                : ListView(
                    children: snapshot.data!.docs
                        .where((element) => element.get("Status") == true)
                        .map(
                          (e) => TodoItem(
                            todo: Todo(
                                id: e.get("id").toString(),
                                header: e.get("Todo Head"),
                                desc: e.get("Todo Desc"),
                                checked: e.get("Status")),
                            onTodoChanged: _completed,
                            popupMenuButton: _deleteTodo,
                          ),
                        )
                        .toList(),
                  );
          }),
    );
  }

  void _completed(Todo todo) {
    setState(() {
      todo.checked = !todo.checked;
      _todosOk.add(todo);
      _todos.remove(todo);
    });
    todo.checked == true
        ? _firebaseFirestore
            .collection("Todos")
            .doc(todo.id.toString())
            .update({"Status": true})
        : _firebaseFirestore
            .collection("Todos")
            .doc(todo.id.toString())
            .update({"Status": false});
  }

  void _deleteTodo(Todo todo) {
    setState(() {
      _todosOk.remove(todo);
      _todos.remove(todo);
    });
    _firebaseFirestore.collection("Todos").doc(todo.id.toString()).delete();
  }

  void _addTodoItem(String desc, String header) {
    var id = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _todos.add(
          Todo(id: id.toString(), header: header, desc: desc, checked: false));
    });
    _firebaseFirestore.collection("Todos").doc(id.toString()).set({
      "id": id,
      "Todo Head": header,
      "Todo Desc": desc,
      "Status": false
    }).whenComplete(() => print("${header} todo kaydedildi"));
    _textFieldController.clear();
    _textFieldControllerHeader.clear();
  }

  Future<void> _displayDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Yeni Todo Ekleyin'),
          content: Container(
            height: 150,
            child: Column(
              children: [
                TextField(
                  maxLines: 1,
                  controller: _textFieldControllerHeader,
                  decoration: const InputDecoration(hintText: 'Başlık Girin'),
                ),
                TextField(
                  minLines: 1,
                  maxLines: 10,
                  controller: _textFieldController,
                  decoration: const InputDecoration(hintText: 'Todo girin ...'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ekle'),
              onPressed: () {
                Navigator.of(context).pop();
                _textFieldControllerHeader.text.length > 1
                    ? _addTodoItem(_textFieldController.text,
                        _textFieldControllerHeader.text)
                    : null;
              },
            ),
          ],
        );
      },
    );
  }
}
