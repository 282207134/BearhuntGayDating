import 'package:flutter/material.dart';

class DemoSession extends ChangeNotifier {
  final profile = <String, String>{};
  final filters = <String, Set<String>>{};
  final messages = <String, List<String>>{};
  RangeValues ages = const RangeValues(18, 35);
  String? location;
  String? chatName;
  bool premium = false;
  bool firstNearby = true;
  bool sharedLocation = false;
  bool pushEnabled = false;
  bool cameraEnabled = false;
  bool emptyChats = false;
  int credits = 500;
  int plan = 0;

  bool get hasFilters =>
      location != null ||
      filters.values.any((set) => set.isNotEmpty) ||
      ages != const RangeValues(18, 35);

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  void selectFilter(String group, String value) {
    update(() {
      final selection = filters.putIfAbsent(group, () => {});
      if (value == 'All') {
        selection.clear();
      } else if (!selection.add(value)) {
        selection.remove(value);
      }
    });
  }

  void send(String text) {
    if (text.trim().isEmpty) return;
    update(
      () => messages
          .putIfAbsent(chatName ?? 'Herman West', () => [])
          .add(text.trim()),
    );
  }
}
