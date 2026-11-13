import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/data/content.dart';
import 'package:paco_bourse/services/market.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final bundled = MarketSnapshot.fromJson(
      (jsonDecode(File('assets/data/market-snapshot.json').readAsStringSync()) as Map).cast());

  test('copie locale plus récente utilisée, plus ancienne ignorée', () async {
    final newer = (jsonDecode(File('assets/data/market-snapshot.json').readAsStringSync()) as Map)
      ..['sessionDate'] = '2099-01-01';
    SharedPreferences.setMockInitialValues({'paco.market.v1': jsonEncode(newer)});
    var prefs = await SharedPreferences.getInstance();
    expect(cachedMarket(prefs, bundled)?.sessionDate, '2099-01-01');

    SharedPreferences.setMockInitialValues({'paco.market.v1': File('assets/data/market-snapshot.json').readAsStringSync()});
    prefs = await SharedPreferences.getInstance();
    expect(cachedMarket(prefs, bundled), isNull);
  });

  test('copie incomplète ou illisible refusée', () async {
    SharedPreferences.setMockInitialValues({'paco.market.v1': '{"sessionDate":"2099-01-01","companies":[]}'});
    expect(cachedMarket(await SharedPreferences.getInstance(), bundled), isNull);
    SharedPreferences.setMockInitialValues({'paco.market.v1': 'pas du json'});
    expect(cachedMarket(await SharedPreferences.getInstance(), bundled), isNull);
  });
}
