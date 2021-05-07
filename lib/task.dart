import 'package:flutter/foundation.dart';

class TaskModel extends ChangeNotifier {
  final String text;
  bool isCompleted;

  TaskModel({this.text, this.isCompleted = false});

  TaskModel.fromJson(Map<String, dynamic> json)
      : text = json['text'],
        isCompleted = json['completed'];

  Map<String, dynamic> toJson() => {'text': text, 'completed': isCompleted};

  void toggle() {
    isCompleted = !isCompleted;
    notifyListeners();
  }
}
