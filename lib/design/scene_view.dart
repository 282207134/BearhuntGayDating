import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'scene.dart';

/// One scene can be used at device size or rendered at its full design height.
class SceneView extends StatelessWidget {
  const SceneView({
    required this.scene,
    this.controls = const [],
    this.footerControls = const [],
    this.textOverrides = const {},
    this.hidden = const {},
    super.key,
  });

  final Scene scene;
  final List<SceneControl> controls;
  final List<SceneControl> footerControls;
  final Map<String, CopyOverride> textOverrides;
  final Set<String> hidden;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 480.0);
        final scale = width / designWidth;
        final viewport = constraints.maxHeight / scale;
        final footer = scene.footer.isEmpty ? 0.0 : designFooterHeight;
        // The keyboard can leave less room than a design's full header.
        final header = math.min(
          scene.header - designStatusHeight,
          math.max(0.0, viewport - footer),
        );
        final body = math.max(0.0, viewport - header - footer);
        final bodyOrigin = designStatusHeight + header;
        final content = math.max(body, scene.bodyEnd - bodyOrigin);
        final viewportExtra = math.max(
          0.0,
          body - (scene.bodyEnd - bodyOrigin),
        );
        final stage = switch (scene.screen) {
          Screen.login || Screen.splash => _Stage(420, viewportExtra),
          Screen.discover ||
          Screen.discoverEmpty => _Stage(510, viewportExtra, extendCard: true),
          _ => const _Stage(0, 0),
        };
        final backdrop = scene.screen.isPremium
            ? Colors.white
            : _backdrop(scene);
        final layout = SizedBox(
          width: designWidth,
          height: viewport,
          child: ColoredBox(
            color: backdrop,
            child: Column(
              children: [
                if (header > 0)
                  _SceneSection(
                    layers: scene.layers,
                    origin: designStatusHeight,
                    height: header,
                    controls: controls,
                    textOverrides: textOverrides,
                    hidden: hidden,
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    key: PageStorageKey(scene.screen),
                    physics: const ClampingScrollPhysics(),
                    child: _SceneSection(
                      layers: scene.layers,
                      origin: bodyOrigin,
                      height: content,
                      controls: controls,
                      stage: stage,
                      textOverrides: textOverrides,
                      hidden: hidden,
                    ),
                  ),
                ),
                if (footer > 0)
                  _SceneSection(
                    layers: scene.footer,
                    origin: designFooterTop,
                    height: footer,
                    controls: footerControls,
                    textOverrides: textOverrides,
                    hidden: hidden,
                  ),
              ],
            ),
          ),
        );
        return Center(
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: FittedBox(alignment: Alignment.topCenter, child: layout),
          ),
        );
      },
    );
  }
}

class _SceneSection extends StatelessWidget {
  const _SceneSection({
    required this.layers,
    required this.origin,
    required this.height,
    this.controls = const [],
    this.stage = const _Stage(0, 0),
    this.textOverrides = const {},
    this.hidden = const {},
  });

  final List<Layer> layers;
  final double origin;
  final double height;
  final List<SceneControl> controls;
  final _Stage stage;
  final Map<String, CopyOverride> textOverrides;
  final Set<String> hidden;

  @override
  Widget build(BuildContext context) {
    final visibleArea = Rect.fromLTWH(0, origin, designWidth, height);
    return SizedBox(
      width: designWidth,
      height: height,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final layer in layers)
              if (stage.place(layer.bounds).overlaps(visibleArea) &&
                  !hidden.contains(layer.id))
                _element(layer),
            for (final control in controls)
              if (stage.place(control.bounds).overlaps(visibleArea))
                Positioned.fromRect(
                  rect: stage.place(control.bounds).shift(Offset(0, -origin)),
                  child: control,
                ),
          ],
        ),
      ),
    );
  }

  Widget _element(Layer layer) {
    final rect = stage.place(layer.bounds).shift(Offset(0, -origin));
    final replacement = textOverrides[layer.id];
    return switch (layer) {
      BoxLayer() => Positioned.fromRect(rect: rect, child: _shape(layer)),
      ImageLayer() => Positioned.fromRect(
        rect: rect,
        child: Image.asset(
          layer.path,
          fit: rect.height > layer.bounds.height ? BoxFit.cover : BoxFit.fill,
          excludeFromSemantics: true,
        ),
      ),
      TextLayer() => Positioned(
        left: rect.left,
        top: rect.top + _textOffset(layer),
        width: replacement?.width ?? rect.width + 1.5,
        child: _copy(layer, replacement),
      ),
    };
  }
}

Color _backdrop(Scene scene) {
  for (final box in scene.layers.reversed.whereType<BoxLayer>()) {
    final rect = box.bounds;
    final fill = box.fill;
    if (fill != null &&
        fill.endsWith('ff') &&
        rect.left <= 1 &&
        rect.right >= designWidth - 1 &&
        rect.top < 80 &&
        rect.bottom >= scene.bodyEnd - 1) {
      return designColor(fill);
    }
  }
  return scene.surface;
}

class _Stage {
  const _Stage(this.threshold, this.extra, {this.extendCard = false});
  final double threshold;
  final double extra;
  final bool extendCard;

  Rect place(Rect rect) {
    if (extra == 0) return rect;
    if (rect.top >= threshold) return rect.shift(Offset(0, extra));
    if (extendCard && rect.bottom > threshold && rect.width >= 330) {
      return Rect.fromLTRB(
        rect.left,
        rect.top,
        rect.right,
        rect.bottom + extra,
      );
    }
    return rect;
  }
}

class SceneControl extends StatelessWidget {
  const SceneControl(this.bounds, this.child, {super.key});
  final Rect bounds;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

Widget _shape(BoxLayer layer) {
  final radius = layer.radius;
  final rounded = radius is List
      ? BorderRadius.only(
          topLeft: Radius.circular((radius[0] as num).toDouble()),
          topRight: Radius.circular((radius[1] as num).toDouble()),
          bottomRight: Radius.circular((radius[2] as num).toDouble()),
          bottomLeft: Radius.circular((radius[3] as num).toDouble()),
        )
      : BorderRadius.circular((radius as num).toDouble());
  return DecoratedBox(
    decoration: BoxDecoration(
      color: layer.fill == null ? null : designColor(layer.fill!),
      borderRadius: rounded,
      border: layer.stroke == null
          ? null
          : Border.all(
              color: designColor(layer.stroke!),
              width: layer.strokeWidth,
            ),
    ),
  );
}

double _textOffset(TextLayer layer) {
  final run = layer.runs.first;
  final normalInset = run.size * (run.family == 'Montserrat' ? .26 : .20);
  final lineInset = run.size * ((run.height ?? 1.2) - 1.2) / 2;
  return layer.inkBounds.top - layer.bounds.top - normalInset - lineInset;
}

TextStyle _style(TextRun run, double opacity) {
  final weight = run.weight.toLowerCase().replaceAll(' ', '');
  return TextStyle(
    color: run.color.withValues(alpha: run.color.a * opacity),
    fontSize: run.size,
    fontFamily: run.family.isEmpty ? null : run.family,
    fontWeight: switch (weight) {
      'black' || 'heavy' => FontWeight.w900,
      'extrabold' => FontWeight.w800,
      'bold' => FontWeight.w700,
      'semibold' || 'demibold' => FontWeight.w600,
      'medium' => FontWeight.w500,
      'light' => FontWeight.w300,
      _ => FontWeight.w400,
    },
    letterSpacing: run.spacing,
    height: run.height ?? 1.19,
    decoration: switch (run.decoration) {
      'UNDERLINE' => TextDecoration.underline,
      'STRIKETHROUGH' => TextDecoration.lineThrough,
      _ => TextDecoration.none,
    },
  );
}

Widget _copy(TextLayer layer, CopyOverride? replacement) {
  final first = layer.runs.first;
  final align = switch (layer.alignment) {
    'CENTER' => TextAlign.center,
    'RIGHT' => TextAlign.right,
    'JUSTIFIED' => TextAlign.justify,
    _ => TextAlign.left,
  };
  final singleLine =
      layer.inkBounds.height <= first.size * 1.28 &&
      layer.runs.every((run) => !run.text.contains('\n'));
  final text = Text.rich(
    TextSpan(
      style: _style(first, layer.opacity),
      text: replacement?.text ?? (layer.runs.length == 1 ? first.text : null),
      children: replacement != null || layer.runs.length == 1
          ? null
          : [
              for (final run in layer.runs)
                TextSpan(text: run.text, style: _style(run, layer.opacity)),
            ],
    ),
    textAlign: align,
    maxLines: replacement?.lines ?? (singleLine ? 1 : null),
    softWrap: replacement != null ? replacement.lines > 1 : !singleLine,
    overflow: replacement != null
        ? TextOverflow.ellipsis
        : TextOverflow.visible,
  );
  if (!singleLine || replacement != null) return text;
  return FittedBox(
    fit: BoxFit.scaleDown,
    alignment: switch (align) {
      TextAlign.center => Alignment.center,
      TextAlign.right => Alignment.centerRight,
      _ => Alignment.centerLeft,
    },
    child: text,
  );
}
