import 'package:another_brother/printer_info.dart';
import 'package:flutter/foundation.dart';

class PrinterModel extends ChangeNotifier {
  String name = "BLE Printer";
  BLEPrinter printer;
  BluetoothPrinter btPrinter;

  PrinterModel(String name, BLEPrinter printer, BluetoothPrinter btPrinter) {
    this.name = name;
    this.printer = printer;
    this.btPrinter = btPrinter;
  }
}