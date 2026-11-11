import 'package:flutter/material.dart';

import '../design/scene.dart';
import 'commands.dart';

const _roles = 'Role';
const _ethnicity = 'Ethnicity';
const _goals = 'Looking for';
const _relationship = 'Relationship status';

void setupControls(Commands c) {
  final state = c.session;
  switch (c.screen) {
    case Screen.login:
      c.button(
        'Connect with Facebook',
        30,
        528,
        316,
        48,
        () => c.home(Screen.setupBasics),
      );
    case Screen.setupBasics:
      c.button(
        'Add a photo',
        132,
        121,
        111,
        114,
        () => c.open(Screen.cameraPermission),
      );
      c.done('Next', () => c.open(Screen.setupRole));
      for (final (i, label) in ['Birthday', 'Height', 'Weight'].indexed) {
        c.button(
          label,
          16,
          305 + 101.0 * i,
          343,
          78,
          () => _editField(c, label),
        );
      }
      _profileCopy(c);
    case Screen.setupRole:
    case Screen.setupEthnicity:
    case Screen.setupGoals:
      c.close();
      final (label, next) = switch (c.screen) {
        Screen.setupRole => (_roles, Screen.setupEthnicity),
        Screen.setupEthnicity => (_ethnicity, Screen.setupGoals),
        _ => (_goals, Screen.setupDone),
      };
      _choose(c, label, multiple: label == _goals);
      if (c.screen == Screen.setupGoals) {
        c.put(
          305,
          29,
          65,
          40,
          TextButton(
            onPressed: () => c.open(next),
            child: const Text(
              'Done',
              style: TextStyle(color: ink, fontSize: 17),
            ),
          ),
        );
      } else {
        c.done('Next', () => c.open(next));
      }
    case Screen.setupDone:
      c.button('Discover', 85, 466, 206, 47, () {
        c.home(Screen.discover);
        state.firstNearby = true;
      });
    default:
      break;
  }
}

void filterControls(Commands c) {
  final state = c.session;
  switch (c.screen) {
    case Screen.filters:
    case Screen.filtersSelected:
      c.close();
      c.done('Done', c.back);
      c.button(
        'Location',
        16,
        105,
        343,
        76,
        () => c.open(state.premium ? Screen.location : Screen.unlockLocation),
      );
      c.button('Role', 16, 206, 343, 76, () => c.open(Screen.filterRole));
      c.button(
        'Ethnicity',
        16,
        307,
        343,
        76,
        () => c.open(Screen.filterEthnicity),
      );
      c.button('Age range', 16, 409, 343, 80, () => _ageRange(c));
      final selected = c.screen == Screen.filtersSelected;
      c.replaceCopy(
        selected ? 'Seattle. USA' : 'Current location (San Francisco)',
        state.location ??
            (selected && state.hasFilters
                ? 'Current location (San Francisco)'
                : null),
        width: 285,
      );
      final roles = _summary(state.filters[_roles]);
      final ethnicity = _summary(state.filters[_ethnicity]);
      if (selected && state.hasFilters) {
        c.replaceCopy('Top, Bottom, Versatile', roles ?? 'All', width: 285);
        c.replaceCopy(
          'Latino, Black, Mixed, Native American ...',
          ethnicity ?? 'All',
          width: 285,
        );
      } else if (!selected) {
        if (roles != null) {
          c.overrides['0:910'] = (text: roles, width: 285, lines: 1);
        }
        if (ethnicity != null) {
          c.overrides['0:916'] = (text: ethnicity, width: 285, lines: 1);
        }
      }
      if (state.ages != const RangeValues(18, 35)) {
        c.replaceCopy(
          '18-35',
          '${state.ages.start.round()}-${state.ages.end.round()}',
        );
      }
    case Screen.filterRole:
    case Screen.filterEthnicity:
      c.close();
      _choose(
        c,
        c.screen == Screen.filterRole ? _roles : _ethnicity,
        filtering: true,
        multiple: true,
      );
    case Screen.location:
      c.close();
      c.done('Done', () {
        state.update(() => state.location ??= 'Seattle, USA');
        c.back();
      });
      c.replaceCopy('Seattle, USA', state.location, width: 299);
      c.button(
        'Enter a city',
        16,
        80,
        343,
        47,
        () => c.editText(
          'City',
          state.location ?? 'Seattle, USA',
          (value) => state.update(() => state.location = value),
        ),
      );
      c.button('Current location', 307, 591, 56, 59, () {
        if (state.sharedLocation) {
          state.update(() => state.location = 'San Francisco, USA');
        } else {
          c.open(Screen.noLocation);
        }
      });
    default:
      break;
  }
}

void profileControls(Commands c) {
  final state = c.session;
  switch (c.screen) {
    case Screen.profile:
      c.replaceCopy('Stephen Conner', state.profile['Full name']);
      c.button('Settings', 0, 25, 54, 44, () => _settings(c));
      c.button('Store', 321, 25, 54, 44, () => c.open(Screen.credits));
      c.button(
        'Edit Profile',
        110,
        320,
        155,
        53,
        () => c.open(Screen.editProfile),
      );
      c.button(
        'My activities',
        31,
        403,
        314,
        46,
        () => c.open(Screen.activitiesEmpty),
      );
      c.button(
        'Reactivate premium',
        31,
        454,
        314,
        46,
        () => c.open(
          state.premium ? Screen.subscriptions : Screen.freeSubscription,
        ),
      );
      c.button('Restore subscription', 31, 505, 314, 46, () {
        if (state.premium) {
          c.open(Screen.subscriptions);
        } else {
          c.notice('No demo subscription to restore.');
        }
      });
      c.button('Rate us', 31, 556, 314, 46, () => c.open(Screen.rate));
    case Screen.editProfile:
      c.close();
      c.done('Done', c.back);
      _profileCopy(c);
      const photos = [
        (16.0, 86.0, 225.0),
        (253.0, 86.0, 106.0),
        (253.0, 205.0, 106.0),
        (16.0, 322.0, 106.0),
        (135.0, 322.0, 106.0),
        (253.0, 322.0, 106.0),
      ];
      for (final (i, (x, y, size)) in photos.indexed) {
        c.button(
          'Edit photo ${i + 1}',
          x,
          y,
          size,
          size,
          () => c.open(Screen.cameraPermission),
        );
      }
      for (final (label, y, height) in [
        ('Full name', 486.0, 45.0),
        ('Birthday', 546.0, 45.0),
        ('About you', 732.0, 106.0),
        ('Height', 859.0, 45.0),
        ('Weight', 921.0, 45.0),
        ('Interests', 1346.0, 48.0),
      ]) {
        c.button(label, 16, y, 343, height, () => _editField(c, label));
      }
      for (final (label, y, next) in [
        (_roles, 609.0, Screen.editRole),
        (_ethnicity, 981.0, Screen.editEthnicity),
        (_relationship, 1042.0, Screen.editRelationship),
        (_goals, 1104.0, Screen.editGoals),
        ('Current location', 1474.0, Screen.location),
      ]) {
        c.button(label, 16, y, 343, 45, () => c.open(next));
      }
    case Screen.editRole:
    case Screen.editEthnicity:
    case Screen.editRelationship:
    case Screen.editGoals:
      c.close();
      final label = switch (c.screen) {
        Screen.editRole => _roles,
        Screen.editEthnicity => _ethnicity,
        Screen.editRelationship => _relationship,
        _ => _goals,
      };
      _choose(
        c,
        label,
        multiple: label == _goals,
        popOnSelect: label != _goals,
      );
    default:
      break;
  }
}

void _settings(Commands c) => c.menu('Settings', {
  'Incognito mode': () =>
      c.open(c.session.premium ? Screen.premiumIncognito : Screen.incognito),
  'Location access': () => c.open(Screen.shareLocation),
  'Push notifications': () => c.open(Screen.pushPermission),
  'Camera access': () => c.open(Screen.cameraPermission),
  'Connection status': () => c.open(Screen.offline),
  'Nearby results': () => c.home(Screen.updateFilters),
  'Show empty chats': () {
    c.session.update(() => c.session.emptyChats = true);
    c.home(Screen.chatsEmpty);
  },
  'Restore demo chats': () {
    c.session.update(() => c.session.emptyChats = false);
    c.home(Screen.chats);
  },
});

String? _summary(Set<String>? selection) => selection == null
    ? null
    : selection.isEmpty
    ? 'All'
    : selection.join(', ');

void _choose(
  Commands c,
  String label, {
  bool multiple = false,
  bool filtering = false,
  bool popOnSelect = false,
}) {
  final state = c.session;
  final saved = state.profile[label];
  final selected = filtering
      ? state.filters[label]
      : saved?.split(', ').toSet();
  if (selected != null) {
    c.hidden.addAll(
      c.scene.layers
          .where(
            (layer) =>
                layer is ImageLayer &&
                layer.bounds.left >= 323 &&
                layer.bounds.top > 76,
          )
          .map((layer) => layer.id),
    );
  }
  for (final option in c.scene.options) {
    final (label: value, :y) = option;
    if (selected != null &&
        (selected.contains(value) || selected.isEmpty && value == 'All')) {
      c.put(330, y - 6, 30, 30, const Icon(Icons.check_rounded, color: accent));
    }
    c.button(value, 12, y - 10, 350, 49, () {
      if (filtering) {
        state.selectFilter(label, value);
      } else {
        final next = {...?selected};
        if (!multiple) next.clear();
        if (!next.add(value)) next.remove(value);
        state.update(() => state.profile[label] = next.join(', '));
      }
      if (popOnSelect) c.back();
    });
  }
}

const _profileDefaults = <String, String>{
  'Full name': 'Landon Gibson',
  'Birthday': 'April 18, 1988',
  'Height': '172 cm',
  'Weight': '75 kg',
  _roles: 'Versatile',
  _ethnicity: 'Asian',
  _relationship: 'Single',
  _goals: 'Friends, Dates, Relationships',
  'Interests': 'Guitar, Music, Fishing, Swimming, Book, Dancing',
};

void _profileCopy(Commands c) {
  for (final entry in _profileDefaults.entries) {
    if (entry.key == 'Interests') continue;
    c.replaceCopy(entry.value, c.session.profile[entry.key]);
  }
  c.replaceCopy('Steattle, USA', c.session.location);
  c.replaceCopy('Add more interests', c.session.profile['Interests']);
  final about = c.session.profile['About you'];
  if (about != null) {
    c.overrides['0:1874'] = (text: about, width: null, lines: 4);
  }
}

Future<void> _editField(Commands c, String label) async {
  final state = c.session;
  if (label == 'Birthday') {
    final result = await showDatePicker(
      context: c.context,
      firstDate: DateTime(1920),
      initialDate: DateTime(1988, 4, 18),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18 + 5)),
    );
    if (result != null && c.context.mounted) {
      final value = MaterialLocalizations.of(c.context).formatFullDate(result);
      state.update(
        () => state.profile[label] = value.split(', ').skip(1).join(', '),
      );
    }
    return;
  }
  await c.editText(
    label,
    state.profile[label] ?? _profileDefaults[label] ?? '',
    (value) => state.update(() => state.profile[label] = value),
    keyboard: label == 'About you'
        ? TextInputType.multiline
        : TextInputType.text,
  );
}

void _ageRange(Commands c) {
  var ages = c.session.ages;
  showModalBottomSheet<void>(
    context: c.context,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (_, setState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Age range · ${ages.start.round()}–${ages.end.round()}'),
              RangeSlider(
                values: ages,
                min: 18,
                max: 80,
                divisions: 62,
                onChanged: (value) => setState(() => ages = value),
              ),
              FilledButton(
                onPressed: () {
                  c.session.update(() => c.session.ages = ages);
                  Navigator.pop(sheetContext);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
