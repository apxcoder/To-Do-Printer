import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:another_brother/custom_paper.dart';
import 'package:another_brother/printer_info.dart';
import 'package:another_brother/type_b_printer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_printer/printer_model.dart';
import 'package:todo_printer/task.dart';

class Manager extends ChangeNotifier {

  static final Manager _instance = Manager.internal();

  factory Manager() {
    return _instance;
  }

  Manager.internal();

  List<TaskModel> tasks = [];
  List<PrinterModel> printers = [];
  final String TASKS_KEY = "tasks";
  BLEPrinter _printer;
  BluetoothPrinter _btPrinter;


  void addTaks(TaskModel task) {
    tasks.add(task);
    notifyListeners();
  }

  void setPrinter(BLEPrinter printer) {
    _printer = printer;
    notifyListeners();
  }

  void setBtPrinter(BluetoothPrinter p) {
    _btPrinter = p;
    notifyListeners();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(TASKS_KEY) ?? '[]';
    final jsonListTasks = jsonDecode(tasksJson).cast<Map<String, dynamic>>();
    tasks = jsonListTasks.map<TaskModel>((m) => TaskModel.fromJson(m)).toList();
    notifyListeners();
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(tasks);
    prefs.setString(TASKS_KEY, json);
  }

  Future<void> getPrinters() async {
    var printer = new Printer();
    var bleFuture = printer.getBLEPrinters(3000);
    var btFuture = printer.getBluetoothPrinters([
      // TODO: Add more printers you want to scan for here.
      Model.QL_1110NWB.getName(),
      Model.PJ_763MFi.getName(),
      TbModel.RJ_2035B.getName()
    ]);


    final List<BLEPrinter> printers = await bleFuture;
    final List<BluetoothPrinter> btPrinters = await btFuture;

    //printer.getBLEPrinters(3000);
    /*this.printers = printers.map((e) => PrinterModel(
      e.localName,
      e
    )).toList();*/

    var bleModelList = printers.map((e) => PrinterModel(
        e.localName,
        e,
        null
    )).toList();

    var btModelList = btPrinters.map((e) => PrinterModel(
        e.modelName,
        null,
        e
    )).toList();

    this.printers.addAll(bleModelList);
    this.printers.addAll(btModelList);

    notifyListeners();
  }

  Future<void> printList(BuildContext context, Future<ByteData> byteData/*Future<Uint8List> image*/) async {
    print("Printer: $_printer");
    var imageResult = loadImage2(await byteData);
    _print(context, await imageResult);
  }

  void delete(TaskModel task) async {
    if(tasks.isNotEmpty) {
      tasks.remove(task);
      saveTasks();
      notifyListeners();
    }
  }

  void _print(BuildContext context, ui.Image image) async {

    if(_printer != null) {
      var printer = new Printer();
      var printInfo = PrinterInfo();
      printInfo.printerModel = Model.RJ_4250WB;
      printInfo.printMode = PrintMode.FIT_TO_PAGE;
      //printInfo.isAutoCut = true;
      printInfo.port = Port.BLE;
      printInfo.binCustomPaper = BinPaper_RJ4250.RD_W4in;
      await printer.setPrinterInfo(printInfo);

      printInfo.setLocalName(_printer.localName);
      printer.setPrinterInfo(printInfo);
      printer.printImage(image);
    } else {

      if(_btPrinter == null) {
        print("NOOOOO");
      }

      var printer = new TbPrinter();
      var printInfo = TbPrinterInfo();
      //printInfo.printerModel = TbModel.RJ_3035B;
      printInfo.port = Port.BLUETOOTH;
      printInfo.btAddress = _btPrinter.macAddress;
      await printer.setPrinterInfo(printInfo);
      bool success = await printer.startCommunication();
      success = await printer.setup();
      success = await printer.clearBuffer();
      success = await printer.downloadImage(image, scale: 0.6);
      success = await printer.printLabel();
      success = await printer.endCommunication(timeoutMillis:10000);
    }
  }

  Future<ui.Image> loadImage2(ByteData byteData) async {
    print("Hi there");
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(new Uint8List.view(byteData.buffer), (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  Future<ui.Image> loadImage(String assetPath) async {
    final ByteData img = await rootBundle.load(assetPath);
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(new Uint8List.view(img.buffer), (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }
}
