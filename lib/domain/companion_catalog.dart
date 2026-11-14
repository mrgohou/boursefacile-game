import 'dart:convert';

import 'package:flutter/services.dart';

/// Offline educational content extracted from the user-supplied APK.
class CompanionCatalog {
  CompanionCatalog(this.cities, this.quiz, this.levels, this.market);
  final List<Map<String, dynamic>> cities, levels;
  final Map<String, dynamic> quiz, market;
  static Future<CompanionCatalog> load() async {
    Future<dynamic> read(String file) async =>
        jsonDecode(await rootBundle.loadString('assets/companion/$file.json'));
    final data = await Future.wait(
      ['cities', 'quiz', 'levels', 'market-snapshot'].map(read),
    );
    final cities = List<Map<String, dynamic>>.from(
      (data[0] as List).map((x) => Map<String, dynamic>.from(x as Map)),
    );
    final quiz = Map<String, dynamic>.from(data[1] as Map);
    final levels = List<Map<String, dynamic>>.from(
      (data[2] as List).map((x) => Map<String, dynamic>.from(x as Map)),
    );
    if (cities.length != 15 || levels.length != 45 || quiz.length != 15) {
      throw const FormatException('Catalogue incomplet.');
    }
    for (var i = 0; i < 15; i++) {
      if (cities[i]['n'] != i + 1 || (quiz['${i + 1}'] as List).length != 3) {
        throw const FormatException('Destination invalide.');
      }
      for (final q in quiz['${i + 1}'] as List) {
        if (q['q'] is! String ||
            q['why'] is! String ||
            (q['a'] as List).length < 2) {
          throw const FormatException('Quiz invalide.');
        }
      }
    }
    return CompanionCatalog(
      cities,
      quiz,
      levels,
      Map<String, dynamic>.from(data[3] as Map),
    );
  }
}
