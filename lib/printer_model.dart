import 'package:another_brother/printer_info.dart';
import 'package:flutter/foundation.dart';

class PrinterModel extends ChangeNotifier {
  String name = "BLE Printer";
  BLEPrinter printer;

  PrinterModel(String name, BLEPrinter printer) {
    this.name = name;
    this.printer = printer;
  }
}