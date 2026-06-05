import 'dart:math';
import '../models/card.dart';
import 'pairs.dart';

const _minute = 60000;
const _hour = 3600000;
const _day = 86400000;

final _random = Random();

TranslationCard _makeCard(int i, int now, List<String> pair, {bool archived = false}) {
  final ageSteps = [
    3 * _minute, 22 * _minute, (1.5 * _hour).toInt(), 5 * _hour, 11 * _hour,
    _day, 2 * _day, 4 * _day, 9 * _day, 21 * _day,
  ];
  final created = now - ageSteps[i % ageSteps.length] - i * 47 * _minute;
  final id = 'c${i}_${_random.nextInt(99999).toString().padLeft(5, '0')}';

  return TranslationCard(
    id: id,
    en: pair[0],
    jp: pair[1],
    romaji: pair[2],
    createdAt: created,
    durationMs: 1600 + (pair[1].length * 90),
    plays: (i * 7) % 13,
    archived: archived,
    status: CardStatus.ready,
  );
}

List<TranslationCard> generateCards({int count = 520}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final out = <TranslationCard>[];
  for (var i = 0; i < count; i++) {
    final pair = pairs[i % pairs.length];
    out.add(_makeCard(i, now, pair, archived: i % 11 == 7));
  }
  return out;
}

List<String> randomPair() {
  return pairs[_random.nextInt(pairs.length)];
}

List<T> shuffleList<T>(List<T> list) {
  final result = List<T>.from(list);
  for (var i = result.length - 1; i > 0; i--) {
    final j = _random.nextInt(i + 1);
    final tmp = result[i];
    result[i] = result[j];
    result[j] = tmp;
  }
  return result;
}
