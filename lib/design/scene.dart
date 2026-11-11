import 'dart:convert';

import 'package:flutter/services.dart';

enum Screen {
  login,
  splash,
  discover,
  swipe,
  discoverEmpty,
  person,
  nearby,
  nearbyLoading,
  spotlight,
  purchaseSuccess,
  match,
  rate,
  incognito,
  activitiesEmpty,
  superlikeLimit,
  filters,
  filtersSelected,
  chats,
  conversation,
  notifications,
  credits,
  subscriptions,
  freeSubscription,
  editEthnicity,
  filterEthnicity,
  editRole,
  filterRole,
  setupBasics,
  setupRole,
  setupEthnicity,
  setupGoals,
  setupDone,
  location,
  editRelationship,
  editGoals,
  profile,
  editProfile,
  unlockVisitors,
  unlockLikes,
  unlockLocation,
  unlockChat,
  offline,
  noLocation,
  updateFilters,
  chatsEmpty,
  conversationEmpty,
  notificationsEmpty,
  shareLocation,
  pushPermission,
  cameraPermission,
  premiumLikes,
  premiumVisitors,
  premiumRewind,
  premiumMessages,
  premiumSpotlight,
  premiumIncognito,
  premiumTravel;

  int get number => index + 1;
  bool get isPremium => index >= premiumLikes.index;
  bool get isConversation => this == conversation || this == conversationEmpty;
}

typedef CopyOverride = ({String text, double? width, int lines});

const designWidth = 375.0;
const designStatusHeight = 20.0;
const designFooterTop = 618.0;
const designFooterHeight = 49.0;
const accent = Color(0xfffacc01);
const paper = Color(0xfff5f6fa);
const ink = Color(0xff262626);

Color designColor(String hex) =>
    Color(int.parse(hex.substring(6) + hex.substring(0, 6), radix: 16));

Rect _rect(List<dynamic> xywh) => Rect.fromLTWH(
  (xywh[0] as num).toDouble(),
  (xywh[1] as num).toDouble(),
  (xywh[2] as num).toDouble(),
  (xywh[3] as num).toDouble(),
);

sealed class Layer {
  const Layer(this.bounds, this.id);
  final Rect bounds;
  final String id;

  factory Layer.decode(List<dynamic> data) {
    final bounds = _rect(data[1] as List);
    return switch (data[0]) {
      'b' => BoxLayer(
        bounds,
        data[6] as String,
        data[2] as String?,
        data[3],
        data[4] as String?,
        (data[5] as num).toDouble(),
      ),
      'i' => ImageLayer(bounds, data[3] as String, data[2] as String),
      't' => TextLayer(
        bounds,
        data[2] as String,
        (data[3] as List)
            .map((e) => TextRun(e as List))
            .toList(growable: false),
        data[4] as String,
        _rect(data[5] as List),
        (data[6] as num).toDouble(),
      ),
      _ => throw const FormatException('Unknown Pixso layer'),
    };
  }
}

class BoxLayer extends Layer {
  const BoxLayer(
    super.bounds,
    super.id,
    this.fill,
    this.radius,
    this.stroke,
    this.strokeWidth,
  );

  final String? fill;
  final Object radius;
  final String? stroke;
  final double strokeWidth;
}

class ImageLayer extends Layer {
  const ImageLayer(super.bounds, super.id, this.asset);
  final String asset;
  String get path => 'assets/pixso/art/$asset.webp';
}

class TextLayer extends Layer {
  const TextLayer(
    super.bounds,
    super.id,
    this.runs,
    this.alignment,
    this.inkBounds,
    this.opacity,
  );
  final List<TextRun> runs;
  final String alignment;
  final Rect inkBounds;
  final double opacity;
}

class TextRun {
  TextRun(List<dynamic> data)
    : text = data[0] as String,
      size = (data[1] as num).toDouble(),
      family = data[2] as String,
      weight = data[3] as String,
      color = designColor(data[4] as String),
      spacing = (data[5] as num).toDouble(),
      height = (data[6] as num?)?.toDouble(),
      decoration = data[7] as String;

  final String text;
  final double size;
  final String family;
  final String weight;
  final Color color;
  final double spacing;
  final double? height;
  final String decoration;
}

class Scene {
  Scene(this.screen, Map<String, dynamic> data)
    : name = data['name'] as String,
      pixsoId = data['pixso'] as String,
      height = (data['height'] as num).toDouble(),
      header = (data['header'] as num).toDouble(),
      bodyEnd = (data['bodyEnd'] as num).toDouble(),
      surface = designColor(data['surface'] as String),
      tabs = data['tabs'] as bool,
      layers = _layers(data['layers'] as List),
      footer = _layers(data['footer'] as List),
      options = (data['options'] as List? ?? const [])
          .map((row) {
            final values = row as List;
            return (
              label: values[0] as String,
              y: (values[1] as num).toDouble(),
            );
          })
          .toList(growable: false);

  final Screen screen;
  final String name;
  final String pixsoId;
  final double height;
  final double header;
  final double bodyEnd;
  final Color surface;
  final bool tabs;
  final List<Layer> layers;
  final List<Layer> footer;
  final List<({String label, double y})> options;

  static List<Layer> _layers(List data) =>
      data.map((e) => Layer.decode(e as List)).toList(growable: false);
}

class SceneLibrary {
  const SceneLibrary(this._scenes);
  final List<Scene> _scenes;
  Scene operator [](Screen screen) => _scenes[screen.index];

  static Future<SceneLibrary> load() async {
    final source = await rootBundle.loadString('assets/pixso/scenes.json');
    final rows = jsonDecode(source) as List;
    if (rows.length != Screen.values.length) {
      throw const FormatException('The screen catalog is incomplete');
    }
    return SceneLibrary([
      for (final screen in Screen.values)
        Scene(screen, rows[screen.index] as Map<String, dynamic>),
    ]);
  }
}
