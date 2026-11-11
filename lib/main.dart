import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design/scene.dart';
import 'design/scene_view.dart';
import 'features/commands.dart';
import 'features/premium.dart';
import 'features/profile.dart';
import 'features/session.dart';
import 'features/social.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final library = await SceneLibrary.load();
  runApp(BearHunt(library: library));
}

class BearHunt extends StatefulWidget {
  const BearHunt({
    required this.library,
    this.initial = Screen.splash,
    this.animateTransitions = true,
    super.key,
  });
  final SceneLibrary library;
  final Screen initial;
  final bool animateTransitions;

  @override
  State<BearHunt> createState() => _BearHuntState();
}

class _BearHuntState extends State<BearHunt> {
  final _session = DemoSession();

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BearHunt',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: const Color(0xff785e00),
        surface: paper,
      ),
      scaffoldBackgroundColor: paper,
    ),
    home: _ScenePage(
      library: widget.library,
      session: _session,
      initial: widget.initial,
      animateTransitions: widget.animateTransitions,
    ),
  );

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }
}

class _ScenePage extends StatefulWidget {
  const _ScenePage({
    required this.library,
    required this.session,
    required this.initial,
    this.animateTransitions = true,
  });
  final SceneLibrary library;
  final DemoSession session;
  final Screen initial;
  final bool animateTransitions;

  @override
  State<_ScenePage> createState() => _ScenePageState();
}

class _ScenePageState extends State<_ScenePage> {
  late Screen _screen = widget.initial;
  final _input = TextEditingController();
  Timer? _transition;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _transition?.cancel();
    if (!widget.animateTransitions) return;
    final next = switch (_screen) {
      Screen.splash => Screen.login,
      Screen.nearbyLoading => Screen.nearby,
      _ => null,
    };
    if (next != null) {
      _transition = Timer(const Duration(milliseconds: 750), () => _show(next));
    }
  }

  void _show(Screen screen) {
    if (screen == _screen) return;
    FocusScope.of(context).unfocus();
    _input.clear();
    setState(() => _screen = screen);
    _schedule();
  }

  Route<void> _route(Screen screen) => MaterialPageRoute(
    settings: RouteSettings(name: screen.name),
    builder: (_) => _ScenePage(
      library: widget.library,
      session: widget.session,
      initial: screen,
    ),
  );

  void _open(Screen screen) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(_route(screen));
  }

  void _home(Screen screen) {
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) {
      _show(screen);
    } else {
      navigator.pushAndRemoveUntil(_route(screen), (_) => false);
    }
  }

  void _back() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      _show(Screen.discover);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) {
      final scene = widget.library[_screen];
      final commands = Commands(
        context: context,
        scene: scene,
        session: widget.session,
        open: _open,
        show: _show,
        home: _home,
        back: _back,
      );
      setupControls(commands);
      discoveryControls(commands);
      filterControls(commands);
      chatControls(commands, _input);
      notificationControls(commands);
      profileControls(commands);
      storeControls(commands);
      dialogControls(commands);
      commands.addTabs();
      final dark = scene.surface.computeLuminance() < .25;
      final bar = dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: bar.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: scene.footer.isEmpty ? scene.surface : ink,
          systemNavigationBarIconBrightness: scene.footer.isEmpty && !dark
              ? Brightness.dark
              : Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: scene.surface,
          body: SafeArea(
            child: SceneView(
              key: ValueKey(_screen),
              scene: scene,
              controls: commands.controls,
              footerControls: commands.footer,
              textOverrides: commands.overrides,
              hidden: commands.hidden,
            ),
          ),
        ),
      );
    },
  );

  @override
  void dispose() {
    _transition?.cancel();
    _input.dispose();
    super.dispose();
  }
}
