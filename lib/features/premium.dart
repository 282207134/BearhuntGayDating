import 'package:flutter/material.dart';

import '../design/scene.dart';
import 'commands.dart';

void storeControls(Commands c) {
  final state = c.session;
  final s = c.screen;

  if (s == Screen.credits ||
      s == Screen.subscriptions ||
      s == Screen.freeSubscription) {
    c.close();
    c.button('Purchase', 83, 25, 109, 45, () => c.show(Screen.credits));
    c.button(
      'Subscriptions',
      197,
      25,
      124,
      45,
      () => c.show(
        state.premium ? Screen.subscriptions : Screen.freeSubscription,
      ),
    );
  }
  switch (s) {
    case Screen.credits:
      c.replaceCopy('500', '${state.credits}');
      for (final (i, (amount, price)) in [
        (100, r'$0.99'),
        (500, r'$3.99'),
        (1000, r'$6.99'),
      ].indexed) {
        c.button(
          'Buy $amount credits',
          16,
          343 + 79.0 * i,
          344,
          58,
          () => _checkout(
            c,
            '$amount credits · $price',
            () => state.credits += amount,
          ),
        );
      }
    case Screen.subscriptions:
      c.button('Renew', 105, 516, 167, 45, () => c.open(Screen.premiumLikes));
      const privileges = [
        (678.0, Screen.premiumLikes),
        (756.0, Screen.premiumVisitors),
        (833.0, Screen.premiumRewind),
        (911.0, Screen.premiumMessages),
        (988.0, Screen.premiumIncognito),
        (1064.0, Screen.premiumSpotlight),
        (1151.0, Screen.premiumTravel),
      ];
      for (final (y, next) in privileges) {
        c.button('Premium benefit', 16, y, 343, 63, () => c.open(next));
      }
    case Screen.freeSubscription:
      c.button(
        'Try premium for free',
        79,
        526,
        218,
        45,
        () => c.open(Screen.premiumLikes),
      );
    case Screen.purchaseSuccess:
      c.button('OK', 85, 447, 206, 45, c.back);
    default:
      break;
  }

  if (!s.isPremium) return;
  const plans = ['7-day trial', '1 month', '3 months'];
  const prices = [r'$4.99/week', r'$14.99/month', r'$13.33/month'];
  final slide = s.index - Screen.premiumLikes.index;
  void selectSlide(int index) {
    if (index >= 0 && index < 7) {
      c.show(Screen.values[Screen.premiumLikes.index + index]);
    }
  }

  c.close();
  c.put(
    4,
    71,
    367,
    108,
    GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 60) selectSlide(slide + (velocity < 0 ? 1 : -1));
      },
    ),
  );
  for (var i = 0; i < 7; i++) {
    c.button(
      'Premium benefit ${i + 1}',
      144 + i * 11.6,
      176,
      11.6,
      26,
      () => selectSlide(i),
    );
  }
  for (final (i, label) in plans.indexed) {
    if (state.plan == i && i != 0) {
      c.put(
        12 + i * 121,
        345,
        109,
        116,
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: accent, width: 2),
          ),
        ),
      );
    }
    c.button(
      label,
      9 + i * 121,
      342,
      114,
      122,
      () => state.update(() => state.plan = i),
    );
  }
  if (state.plan != 0) c.replaceCopy('Start Trial now', 'Continue');
  c.button('Continue with ${plans[state.plan]}', 8, 606, 359, 45, () {
    final plan = state.plan;
    _checkout(
      c,
      '${plans[plan]} · ${prices[plan]}',
      () => state.premium = true,
    );
  }, radius: 23);
}

Future<void> _checkout(Commands c, String item, VoidCallback apply) async {
  final result = await showDialog<bool>(
    context: c.context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Demo purchase'),
      content: Text('$item\n\nNo payment will be charged.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  if (result == true && c.context.mounted) {
    c.session.update(apply);
    c.open(Screen.purchaseSuccess);
  }
}

void dialogControls(Commands c) {
  final state = c.session;
  void premium(Screen next) => c.show(next);
  switch (c.screen) {
    case Screen.incognito:
    case Screen.unlockVisitors:
    case Screen.unlockLikes:
    case Screen.unlockLocation:
    case Screen.unlockChat:
      final next = switch (c.screen) {
        Screen.incognito => Screen.premiumIncognito,
        Screen.unlockVisitors => Screen.premiumVisitors,
        Screen.unlockLikes => Screen.premiumLikes,
        Screen.unlockLocation => Screen.premiumTravel,
        _ => Screen.premiumMessages,
      };
      final incognito = c.screen == Screen.incognito;
      c.button(
        'Activate premium',
        85,
        incognito ? 468 : 434,
        206,
        45,
        () => premium(next),
      );
      c.button('No, thanks', 85, incognito ? 521 : 493, 206, 45, c.back);
    case Screen.superlikeLimit:
      c.button(
        'Activate premium',
        85,
        448,
        206,
        45,
        () => premium(Screen.premiumLikes),
      );
      c.button('Use 100 credits', 85, 508, 206, 45, () {
        if (state.credits < 100) {
          c.show(Screen.credits);
        } else {
          state.update(() => state.credits -= 100);
          c.show(Screen.match);
        }
      });
      c.button('No, thanks', 85, 559, 206, 45, c.back);
    case Screen.activitiesEmpty:
      c.button('Okay', 85, 482, 206, 45, c.back);
    case Screen.rate:
      c.button('Rate us', 85, 397, 206, 44, () {
        c.notice('Thanks for trying BearHunt.');
        c.back();
      });
      c.button('Maybe later', 85, 446, 206, 44, c.back);
    case Screen.offline:
      c.button('Try again', 85, 448, 206, 45, c.back);
    case Screen.noLocation:
      c.button(
        'Open Settings',
        85,
        448,
        206,
        45,
        () => c.show(Screen.shareLocation),
      );
    case Screen.shareLocation:
    case Screen.pushPermission:
    case Screen.cameraPermission:
      final label = c.screen == Screen.shareLocation
          ? 'Share location'
          : 'Allow';
      c.button(label, 85, 468, 206, 45, () {
        state.update(() {
          switch (c.screen) {
            case Screen.shareLocation:
              state.sharedLocation = true;
            case Screen.pushPermission:
              state.pushEnabled = true;
            case Screen.cameraPermission:
              state.cameraEnabled = true;
            default:
              break;
          }
        });
        c.back();
      });
      c.button('Skip', 85, 520, 206, 45, c.back);
    default:
      break;
  }
}
