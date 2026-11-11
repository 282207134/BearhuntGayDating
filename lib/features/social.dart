import 'package:flutter/material.dart';

import '../design/scene.dart';
import 'commands.dart';

void discoveryControls(Commands c) {
  final s = c.screen;
  final state = c.session;
  void filters() =>
      c.open(state.hasFilters ? Screen.filtersSelected : Screen.filters);
  void person() => c.open(Screen.person);
  switch (s) {
    case Screen.discover:
    case Screen.swipe:
      c.put(
        16,
        83,
        343,
        515,
        Semantics(
          button: true,
          label: 'Open profile. Swipe right to like or left to pass.',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: person,
            onHorizontalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0).abs() < 70) return;
              c.show(
                details.primaryVelocity! > 0 && s == Screen.discover
                    ? Screen.swipe
                    : Screen.discoverEmpty,
              );
            },
          ),
        ),
      );
      c.button(
        'Superlike',
        274,
        510,
        79,
        79,
        () =>
            c.open(s == Screen.discover ? Screen.match : Screen.superlikeLimit),
        radius: 40,
      );
      if (s == Screen.swipe) {
        c.button('Rewind', 4, 26, 46, 44, () => c.show(Screen.discover));
      }
      c.button('Filters', 315, 26, 60, 45, filters);
    case Screen.discoverEmpty:
      c.button('Filters', 315, 26, 60, 45, filters);
      c.button('Try nearby', 22, 83, 331, 515, () => c.home(Screen.nearby));
    case Screen.person:
      c.button('Close profile', 10, 35, 52, 52, c.back);
      c.button(
        'Profile options',
        310,
        35,
        56,
        55,
        () => c.menu('Profile options', {
          'Share profile': () => c.notice('Clayton Roy · Seattle, USA'),
          'Hide profile': () => c.home(Screen.discoverEmpty),
        }),
      );
      c.button(
        'Show more',
        12,
        695,
        147,
        36,
        () => c.menu('About Clayton', {
          'I enjoy reading, teaching and meeting new people.': () {},
        }),
      );
      c.button(
        'Like',
        76,
        1358,
        64,
        66,
        () => c.open(Screen.match),
        radius: 35,
      );
      c.button(
        'Superlike',
        156,
        1358,
        64,
        66,
        () => c.open(Screen.superlikeLimit),
        radius: 35,
      );
      c.button(
        'Message',
        236,
        1358,
        64,
        66,
        () => c.open(
          state.premium ? Screen.conversationEmpty : Screen.unlockChat,
        ),
        radius: 35,
      );
    case Screen.nearby:
    case Screen.nearbyLoading:
    case Screen.spotlight:
    case Screen.updateFilters:
      c.button('Spotlight', 93, 26, 95, 44, () => c.show(Screen.spotlight));
      c.button('Nearby', 190, 26, 96, 44, () => c.show(Screen.nearby));
      c.button('Filters', 314, 26, 61, 44, filters);
      if (s == Screen.nearby) {
        for (var row = 0; row < 5; row++) {
          for (final x in [7.0, 129.0, 252.0]) {
            c.button(
              'View nearby profile',
              x,
              78 + row * 122,
              114,
              114,
              person,
            );
          }
        }
      }
      if (s == Screen.spotlight) {
        c.button(
          'Add me here',
          8,
          78,
          175,
          176,
          () => c.open(Screen.premiumSpotlight),
        );
        for (var row = 0; row < 3; row++) {
          for (final x in row == 0 ? [191.0] : [7.0, 191.0]) {
            c.button(
              'View spotlight profile',
              x,
              78 + row * 184,
              176,
              176,
              person,
            );
          }
        }
      }
      if (s == Screen.updateFilters) {
        c.button('Update filter', 85, 482, 206, 45, filters);
      }
    case Screen.match:
      c.button('Send a message', 85, 449, 206, 45, () {
        state.chatName = 'Gavin Daniels';
        c.show(Screen.conversationEmpty);
      });
      c.button('Keep playing', 85, 503, 206, 45, c.back);
    default:
      break;
  }
}

void chatControls(Commands c, TextEditingController input) {
  final s = c.screen;
  final state = c.session;
  void conversation(String name, {bool empty = false}) {
    state.chatName = name;
    c.open(empty ? Screen.conversationEmpty : Screen.conversation);
  }

  if (s == Screen.chats || s == Screen.chatsEmpty) {
    const people = [
      'Danny Rice',
      'Jane Gibson',
      'Hattie Hampton',
      'Betty Schwartz',
      'Clara Griffin',
      'Jesse Cooper',
    ];
    c.button(
      'Search chats',
      321,
      25,
      54,
      45,
      () => c.editText('Search chats', '', (query) {
        final matches = people.where(
          (name) => name.toLowerCase().contains(query.toLowerCase()),
        );
        if (matches.isEmpty || s == Screen.chatsEmpty) {
          c.notice('No conversations found');
        } else {
          c.menu('Search results', {
            for (final name in matches) name: () => conversation(name),
          });
        }
      }),
    );
    if (s == Screen.chats) {
      for (final (index, name) in people.indexed) {
        c.button(
          'Chat with $name',
          16,
          87 + index * 87.8,
          343,
          78,
          () => conversation(name, empty: index == 2),
        );
      }
    } else {
      c.button('Discover', 85, 482, 206, 45, () => c.home(Screen.discover));
    }
  }

  if (!s.isConversation) return;
  final name =
      state.chatName ??
      (s == Screen.conversation ? 'Herman West' : 'Hattie Hampton');
  final messages = state.messages[name] ?? const <String>[];
  void send([String? value]) {
    state.chatName = name;
    state.send(value ?? input.text);
    input.clear();
  }

  c.replaceCopy(
    s == Screen.conversation ? 'Herman West' : 'Hattie Hampton',
    name,
  );
  c.close();
  c.button(
    'Conversation options',
    320,
    25,
    55,
    45,
    () => c.menu(name, {
      'View profile': () => c.open(Screen.person),
      'Clear sent messages': () =>
          state.update(() => state.messages.remove(name)),
    }),
  );
  c.button('Camera', 0, 618, 47, 49, () {
    if (state.cameraEnabled) {
      c.notice('Camera access is enabled for this demo.');
    } else {
      c.open(Screen.cameraPermission);
    }
  }, fixed: true);
  c.button('Send message', 331, 618, 44, 49, send, fixed: true);
  c.hidden.addAll(['I0:1045;0:2818', 'I0:2176;0:2818']);
  c.put(
    58,
    625,
    268,
    35,
    TextField(
      controller: input,
      textInputAction: TextInputAction.send,
      onSubmitted: send,
      style: const TextStyle(color: ink, fontSize: 14),
      decoration: const InputDecoration(
        border: InputBorder.none,
        isCollapsed: true,
        contentPadding: EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        hintText: 'Type a message...',
        hintStyle: TextStyle(color: Color(0xff9b9b9b)),
      ),
    ),
    fixed: true,
  );
  if (s == Screen.conversationEmpty && messages.isEmpty) {
    c.button('Say hello', 85, 436, 206, 45, () => send('Hello!'));
  }
  if (messages.isNotEmpty) {
    final top = s == Screen.conversation ? 501.0 : 114.0;
    if (s == Screen.conversationEmpty) {
      c.put(0, 70, 375, 548, const ColoredBox(color: paper));
    }
    c.put(
      18,
      top,
      341,
      designFooterTop - top,
      ListView(
        reverse: true,
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        children: [
          for (final message in messages.reversed)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 255),
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(message, style: const TextStyle(color: ink)),
              ),
            ),
        ],
      ),
    );
  }
}

void notificationControls(Commands c) {
  final s = c.screen;
  if (s != Screen.notifications && s != Screen.notificationsEmpty) return;
  c.button('Likes', 59, 25, 77, 45, () => c.show(Screen.notifications));
  c.button('Matches', 138, 25, 83, 45, () => c.show(Screen.notificationsEmpty));
  c.button('Visitors', 230, 25, 82, 45, () => c.open(Screen.unlockVisitors));
  c.button(
    'Notification settings',
    319,
    25,
    56,
    45,
    () => c.open(Screen.pushPermission),
  );
  if (s == Screen.notifications) {
    c.button('Activate', 263, 74, 101, 58, () => c.open(Screen.premiumLikes));
    for (var row = 0; row < 6; row++) {
      c.button(
        'View notification',
        12,
        148 + row * 92.6,
        350,
        81,
        () => c.open(c.session.premium ? Screen.person : Screen.unlockLikes),
      );
    }
  } else {
    c.button(
      'Activate premium',
      85,
      482,
      206,
      45,
      () => c.open(Screen.premiumLikes),
    );
  }
}
