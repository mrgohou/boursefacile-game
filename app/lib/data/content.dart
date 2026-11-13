// Contenus du jeu chargés depuis assets/data (villes, niveaux, quiz, instantané de marché).
import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;

import '../engine/board.dart';
import '../engine/city.dart';

class CityInfo {
  const CityInfo({
    required this.n,
    required this.name,
    required this.country,
    required this.notion,
    required this.featured,
    required this.pacoIntro,
    required this.retiens,
  });
  factory CityInfo.fromJson(Map<String, dynamic> j) => CityInfo(
        n: j['n'] as int,
        name: j['name'] as String,
        country: j['country'] as String,
        notion: j['notion'] as String,
        featured: j['featured'] as String,
        pacoIntro: j['pacoIntro'] as String,
        retiens: j['retiens'] as String,
      );
  final int n;
  final String name, country, notion, featured, pacoIntro, retiens;
}

class Question {
  const Question(this.q, this.answers, this.why);
  factory Question.fromJson(Map<String, dynamic> j) =>
      Question(j['q'] as String, (j['a'] as List).cast<String>(), j['why'] as String);
  final String q;
  final List<String> answers; // la première est la bonne
  final String why;
  String get good => answers.first;
}

class MarketSnapshot {
  const MarketSnapshot(this.sessionDate, this.companies);
  factory MarketSnapshot.fromJson(Map<String, dynamic> j) => MarketSnapshot(
        j['sessionDate'] as String,
        (j['companies'] as List).map((c) => Company.fromJson((c as Map).cast())).toList(),
      );
  final String sessionDate;
  final List<Company> companies;
}

class Content {
  const Content({required this.cities, required this.levels, required this.quiz, required this.market});

  static Future<Content> load(AssetBundle bundle) async {
    Future<dynamic> json(String name) async => jsonDecode(await bundle.loadString('assets/data/$name'));
    final cities = (await json('cities.json') as List).map((c) => CityInfo.fromJson((c as Map).cast())).toList();
    final levels = (await json('levels.json') as List).map((l) => LevelDef.fromJson((l as Map).cast())).toList();
    final quizRaw = (await json('quiz.json') as Map).cast<String, dynamic>();
    final quiz = {
      for (final e in quizRaw.entries)
        int.parse(e.key): (e.value as List).map((q) => Question.fromJson((q as Map).cast())).toList(),
    };
    final market = MarketSnapshot.fromJson((await json('market-snapshot.json') as Map).cast());
    return Content(cities: cities, levels: levels, quiz: quiz, market: market);
  }

  final List<CityInfo> cities;
  final List<LevelDef> levels;
  final Map<int, List<Question>> quiz;
  final MarketSnapshot market;

  List<LevelDef> levelsOf(int city) => levels.where((l) => l.city == city).toList();
}
