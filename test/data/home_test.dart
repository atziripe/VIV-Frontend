import 'package:flutter_test/flutter_test.dart';
import 'package:viv/data/models/catalog.dart';
import 'package:viv/data/models/home.dart';

void main() {
  test('HomeToday parses GET /home/today', () {
    final h = HomeToday.fromJson({
      'date': '2026-09-10',
      'weekday': 'thursday',
      'week_number': 6,
      'current_phase': 'follicular',
      'next_phase': 'ovulatory',
      'days_until_next_phase': 3,
      'now_card': {
        'time': '18:00',
        'kind': 'session',
        'status': 'pending',
        'title': 'Lower strength · 60 min',
        'is_estimated': true,
        'label': 'IN 15 MIN',
        'cta_label': 'Start session',
        'cta_action': 'POST /training/weekly-plan/day/start',
      },
      'timeline': [
        {'time': '07:40', 'kind': 'checkin', 'status': 'done', 'title': 'Checked in'},
        {'kind': 'meal', 'status': 'upcoming', 'title': 'Lunch'}, // no time
      ],
      'week_progress': {
        'completed_sessions': 1,
        'total_sessions': 3,
        'days': [
          {'weekday': 'monday', 'status': 'done'},
          {'weekday': 'thursday', 'status': 'pending', 'is_today': true},
        ],
      },
    });
    expect(h.weekNumber, 6);
    expect(h.currentPhase, CyclePhase.follicular);
    expect(h.nowCard?.kind, TimelineKind.session);
    expect(h.nowCard?.showsTime, isTrue);
    expect(h.nowCard?.ctaLabel, 'Start session');
    expect(h.timeline.first.isDone, isTrue);
    expect(h.timeline.last.time, isNull);
    expect(h.weekProgress?.days.last.letter, 'T');
    expect(h.isRestDay, isFalse);
  });

  test('now_card can be null and kinds degrade to unknown', () {
    final h = HomeToday.fromJson({
      'date': '2026-09-10',
      'timeline': [
        {'kind': 'something_new', 'status': 'weird', 'title': 'x'},
      ],
    });
    expect(h.nowCard, isNull);
    expect(h.timeline.single.kind, TimelineKind.unknown);
    expect(h.timeline.single.status, TimelineStatus.upcoming);
  });

  test('TODAY / TONIGHT labels carry no clock time', () {
    final card = NowCard.fromJson({'kind': 'lights_out', 'label': 'TONIGHT', 'time': '23:00'});
    expect(card.showsTime, isFalse);
  });

  test('phaseCountdownText', () {
    const f = CyclePhase.follicular, o = CyclePhase.ovulatory;
    expect(phaseCountdownText(f, o, 3), 'Follicular phase · Ovulatory in 3 days');
    expect(phaseCountdownText(f, o, 1), 'Follicular phase · Ovulatory tomorrow');
    expect(phaseCountdownText(f, o, 0), 'Follicular phase · Ovulatory starts today');
    expect(phaseCountdownText(f, null, 5), 'Follicular phase · Next phase in 5 days');
    expect(phaseCountdownText(f, o, null), 'Follicular phase');
    expect(phaseCountdownText(null, null, null), isNull);
  });

  group('composeHomeEntries', () {
    const checkin = TimelineItem(
      kind: TimelineKind.checkin,
      status: TimelineStatus.done,
      title: 'Checked in',
      time: '07:40',
    );
    const breakfast = TimelineItem(
      kind: TimelineKind.meal,
      status: TimelineStatus.done,
      title: 'Breakfast',
      time: '08:00',
    );
    const session = TimelineItem(
      kind: TimelineKind.session,
      status: TimelineStatus.pending,
      title: 'Lower strength · 60 min',
      time: '18:00',
    );
    const dinner = TimelineItem(
      kind: TimelineKind.meal,
      status: TimelineStatus.upcoming,
      title: 'Dinner',
      time: '20:00',
    );

    test('replaces the matching row with the card', () {
      const card = NowCard(
        kind: TimelineKind.session,
        status: TimelineStatus.pending,
        title: 'Lower strength · 60 min',
        time: '18:00',
      );
      final e = composeHomeEntries([checkin, breakfast, session, dinner], card);
      expect(e, hasLength(4));
      expect(e[2], isA<HomeNowEntry>());
    });

    test('without a matching row, sits before the first open item', () {
      const card = NowCard(
        kind: TimelineKind.recoveryAction,
        status: TimelineStatus.pending,
        title: 'Walk 20 minutes',
      );
      final e = composeHomeEntries([checkin, dinner], card);
      expect(e, hasLength(3));
      expect(e[1], isA<HomeNowEntry>());
    });

    test('goes last when everything is done, and nothing changes with no card', () {
      const card = NowCard(
        kind: TimelineKind.lightsOut,
        status: TimelineStatus.pending,
        title: 'Lights out by 23:00',
      );
      expect(composeHomeEntries([checkin, breakfast], card).last, isA<HomeNowEntry>());
      expect(composeHomeEntries([checkin, breakfast], null), hasLength(2));
    });
  });
}
