import 'package:flutter/material.dart';

import '../design/scene.dart';
import '../design/scene_view.dart';
import 'session.dart';

class Commands {
  Commands({
    required this.context,
    required this.scene,
    required this.session,
    required this.open,
    required this.show,
    required this.home,
    required this.back,
  });

  final BuildContext context;
  final Scene scene;
  final DemoSession session;
  final ValueChanged<Screen> open;
  final ValueChanged<Screen> show;
  final ValueChanged<Screen> home;
  final VoidCallback back;
  final controls = <SceneControl>[];
  final footer = <SceneControl>[];
  final overrides = <String, CopyOverride>{};
  final hidden = <String>{};

  Screen get screen => scene.screen;

  void put(
    double x,
    double y,
    double w,
    double h,
    Widget child, {
    bool fixed = false,
  }) {
    (fixed ? footer : controls).add(
      SceneControl(Rect.fromLTWH(x, y, w, h), child),
    );
  }

  void button(
    String label,
    double x,
    double y,
    double w,
    double h,
    VoidCallback onTap, {
    bool fixed = false,
    double radius = 8,
  }) {
    put(
      x,
      y,
      w,
      h,
      Material(
        type: MaterialType.transparency,
        child: Semantics(
          button: true,
          label: label,
          child: InkWell(
            key: ValueKey(label),
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            splashColor: const Color(0x33facc01),
          ),
        ),
      ),
      fixed: fixed,
    );
  }

  void close({bool right = false}) =>
      button('Back', right ? 319 : 0, 25, 52, 45, back);
  void done(String label, VoidCallback action) =>
      button(label, 299, 25, 76, 45, action);

  void replaceCopy(
    String original,
    String? value, {
    double? width,
    int lines = 1,
  }) {
    if (value == null) return;
    for (final text in scene.layers.whereType<TextLayer>()) {
      if (text.runs.map((run) => run.text).join().trim() == original) {
        overrides[text.id] = (text: value, width: width, lines: lines);
      }
    }
  }

  void notice(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> editText(
    String label,
    String initial,
    ValueChanged<String> save, {
    TextInputType keyboard = TextInputType.text,
  }) async {
    var value = initial;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(label),
        content: TextFormField(
          autofocus: true,
          initialValue: initial,
          keyboardType: keyboard,
          onChanged: (text) => value = text,
          onFieldSubmitted: (text) => Navigator.pop(dialogContext, text),
          maxLines: keyboard == TextInputType.multiline ? 4 : 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, value),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (context.mounted && result != null && result.trim().isNotEmpty) {
      save(result.trim());
    }
  }

  void menu(String title, Map<String, VoidCallback> items) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (final item in items.entries)
              ListTile(
                title: Text(item.key),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext);
                  item.value();
                },
              ),
          ],
        ),
      ),
    );
  }

  void addTabs() {
    if (!scene.tabs) return;
    final tabs = <(String, VoidCallback)>[
      (
        'Nearby',
        () {
          if (session.firstNearby) {
            session.firstNearby = false;
            home(Screen.nearbyLoading);
          } else {
            home(Screen.nearby);
          }
        },
      ),
      ('Discover', () => home(Screen.discover)),
      (
        'Chat',
        () => home(session.emptyChats ? Screen.chatsEmpty : Screen.chats),
      ),
      ('Notifications', () => home(Screen.notifications)),
      ('Profile', () => home(Screen.profile)),
    ];
    for (final (index, tab) in tabs.indexed) {
      button(
        tab.$1,
        index * 75,
        designFooterTop,
        75,
        designFooterHeight,
        tab.$2,
        fixed: true,
      );
    }
  }
}
