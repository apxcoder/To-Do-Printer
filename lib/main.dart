import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:todo_printer/printer_model.dart';
import 'package:todo_printer/task.dart';
import 'package:todo_printer/manager.dart';
import 'dart:ui' as ui;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo Printer',
      theme: ThemeData(

        primarySwatch: Colors.blueGrey,
      ),
      home: MyHomePage(title: 'Todo Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    var todoListWidget = TodoListWidget();

    final Manager manager = Manager();
    manager.loadTasks();
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do Printer'),
      ),
      body: ChangeNotifierProvider.value(
        value: manager,
        child: todoListWidget,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Visibility(
          visible: true,
          child: FloatingActionButton(
              backgroundColor: Colors.amberAccent,
              onPressed: () {
                var image = todoListWidget._capturePng();
                manager.printList(context, image);
              },
              tooltip: 'Print',
              child: Icon(
                Icons.print,
                color: Colors.blueGrey,
              ))),
      bottomNavigationBar: BottomAppBar(
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.menu),
              color: Colors.white,
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.settings),
              color: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SecondRoute()),
                );
              },
            ),
          ],
        ),
        color: Colors.blueGrey,
        shape: CircularNotchedRectangle(),
      ),
    );
  }
}

class TodoListWidget extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  GlobalKey _globalKey = new GlobalKey();
  bool inside = false;
  Uint8List imageInMemory;

  Future<ByteData> _capturePng() async {
    try {
      inside = true;
      RenderRepaintBoundary boundary =
          _globalKey.currentContext.findRenderObject();
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      //Uint8List pngBytes = byteData.buffer.asUint8List();
      var p = byteData.buffer;
      print('png done');
      return byteData;
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: Consumer<Manager>(builder: (context, tasks, child) {
        return RepaintBoundary(
            key: _globalKey,
            child: Container(
                color: Colors.white,
                child: ListView(
                  children: tasks.tasks.map((TaskModel task) {
                    return ChangeNotifierProvider.value(
                        value: task, child: TaskWidget());
                  }).toList(),
                )));
      })),
      Consumer<Manager>(
        builder: (context, taskManager, child) {
          return Padding(
              padding: const EdgeInsets.all(60.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.lightBlueAccent)),
                    labelText: 'New task'),
                onSubmitted: (newTask) {
                  taskManager.addTaks(TaskModel(
                      text:
                          newTask)); // create new instance of task changeNotifier model
                  _controller
                      .clear(); // clear the text input after adding tasks
                  taskManager.saveTasks();
                },
              ));
        },
      )
    ]);
  }
}

class TaskWidget extends StatelessWidget {
  TextStyle _taskStyle(isCompleted) {
    if (isCompleted)
      return TextStyle(
        color: Colors.black87,
        decoration: TextDecoration.lineThrough,
      );
    else
      return TextStyle(decoration: TextDecoration.none);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskModel>(builder: (context, task, child) {
      return GestureDetector(
        onPanUpdate: (details) {
          if(details.delta.dx < 0) {
            Manager().delete(task);
          }
        },
        child: CheckboxListTile(
        title: Text(
          task.text,
          style: _taskStyle(task.isCompleted),
        ),
        value: task.isCompleted,
        onChanged: (newValue) {
          task.toggle();
        },
        controlAffinity: ListTileControlAffinity.leading,
          )
      );
    });
  }
}

class SecondRoute extends StatelessWidget {
  final Manager manager = Manager();

  @override
  Widget build(BuildContext context) {
    manager.getPrinters();
    return Scaffold(
      appBar: AppBar(
        title: Text("Printer Settings"),
      ),
      body: ChangeNotifierProvider.value(
        value: manager,
        child: PrinterListWidget(),
      ),
    );
  }
}

class PrinterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PrinterModel>(builder: (context, printer, child) {
      return InkWell(
          onTap: () {
            Manager().setPrinter(printer.printer);
          },
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.print, size: 30),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: Text(
                      printer.name,
                      style: TextStyle(fontSize: 20),
                    )
                  ),

                ],
              )));
    });
  }
}

class PrinterListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: Consumer<Manager>(builder: (context, manager, child) {
        return ListView(
          children: manager.printers.map((PrinterModel printer) {
            return ChangeNotifierProvider.value(
                value: printer, child: PrinterWidget());
          }).toList(),
        );
      })),
    ]);
  }
}
