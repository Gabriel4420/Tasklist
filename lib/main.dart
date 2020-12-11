import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  final toDoController = TextEditingController();

  void addTodo() {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = toDoController.text;
      toDoController.text = "";
      newTodo["ok"] = false;
      _toDoList.add(newTodo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((task1, task2) {
        if (task1["ok"] && !task2["ok"]) {
          return 1;
        } else if (!task1["ok"] && task2["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
    });
  }

  // Desenho da tela do aplicativo -- Interface do usuario
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Task List"),
          backgroundColor: Colors.lightBlueAccent,
          centerTitle: true),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(17),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "New task",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                    controller: toDoController,
                  ),
                ),
                RaisedButton(
                  color: Colors.green[300],
                  child: Text("Add task"),
                  textColor: Colors.white70,
                  onPressed: addTodo,
                ),
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: EdgeInsets.only(top: 10.0),
              itemCount: _toDoList.length,
              itemBuilder: buildItem,
            ),
          ))
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(Icons.delete, color: Colors.white),
          )),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();
        });

        final snack = SnackBar(
          content: Text("Task ${_lastRemoved["title"]} deleted!"),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                _toDoList.insert(_lastRemovedPos, _lastRemoved);
                _saveData();
              });
            },
          ),
          duration: Duration(seconds: 4),
        );

        // ignore: deprecated_member_use
        Scaffold.of(context).removeCurrentSnackBar();
        // ignore: deprecated_member_use
        Scaffold.of(context).showSnackBar(snack);
        
      },
    );
  }

  // Funções async de arquivos
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    //codificando toDoList
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  // ignore: unused_element
  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
