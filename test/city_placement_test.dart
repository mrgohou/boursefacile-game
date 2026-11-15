import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/domain/player_state.dart';

PlayerState owned() {
  var s = PlayerState.initial();
  for (var i = 0; i < 6; i++) {
    s = s.completeLevel(i).answerLesson(i);
  }
  return s.buy('SNTS').buy('ETIT');
}

void main() {
  test('all market companies have a placeable representative and occupied sites cannot overlap', () {
    var s = owned().placeCompany('SNTS', 'centre', 0);
    expect(s.placements['SNTS']!.cell, 0);
    expect(() => s.placeCompany('ETIT', 'centre', 0), throwsStateError);
    expect(() => s.placeCompany('LNBB', 'centre', 1), throwsStateError);
    s = s.placeCompany('ETIT', 'centre', 1).placeCompany('SNTS', 'centre', 2);
    expect(s.placements.length, 2);
    expect(s.placements['SNTS']!.cell, 2);
    expect(PlayerState.fromJson(s.toJson()).toJson(), s.toJson());
  });
  test('districts support multiple acquired companies and final sale releases the site', () {
    var s = owned();
    expect(() => s.placeCompany('SNTS', 'rive', 0), throwsStateError);
    s = s
        .buyLand('rive')
        .placeCompany('SNTS', 'rive', 0)
        .placeCompany('ETIT', 'rive', 1);
    expect(s.placements.length, 2);
    s = s.sell('SNTS');
    expect(s.placements.containsKey('SNTS'), false);
    expect(s.companyCards.contains('SNTS'), true);
  });
  test('v5 holdings migrate without placements, while malformed v6 placements are rejected', () {
    final raw = owned().toJson()
      ..['version'] = 5
      ..remove('placements');
    final s = PlayerState.fromJson(raw);
    expect(s.placements, isEmpty);
    expect(s.holdings['SNTS'], 1);
    final corrupt = s.toJson();
    corrupt['placements'] = {
      'SNTS': {'landId': 'centre', 'cell': 99},
    };
    expect(() => PlayerState.fromJson(corrupt), throwsFormatException);
  });
}
