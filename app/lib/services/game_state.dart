// État de la partie : progression, épargne, ville, cartes, quiz, avis. Sauvegarde locale robuste.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/content.dart';
import '../engine/board.dart';
import '../engine/city.dart';
import 'market.dart';

const goatScore = 700;

class TesterFeedback {
  const TesterFeedback(this.compris, this.amusant, this.changer);
  final int compris, amusant;
  final String changer;
  Map<String, dynamic> toJson() => {'compris': compris, 'amusant': amusant, 'changer': changer};
}

class GameState extends ChangeNotifier {
  GameState(this.content, this._prefs) : market = cachedMarket(_prefs, content.market) ?? content.market {
    _load();
  }

  /// Cours en vigueur : instantané intégré, ou copie plus récente reçue du serveur.
  MarketSnapshot market;

  static const _key = 'paco.save.v1';
  final Content content;
  final SharedPreferences _prefs;
  Timer? _saveTimer;

  // ---- Données sauvegardées ----
  double savings = 10000;
  Map<String, int> stars = {};
  Set<int> seenIntro = {};
  late CityState city;
  Set<String> days = {};
  Map<int, int> quiz = {};
  List<String> cards = [];
  Map<int, TesterFeedback> feedback = {};
  bool pacoDiscret = false;

  List<Company> get companies => market.companies;

  /// Nouveaux cours reçus : référence mise à jour, prix manquants ajoutés (nouvelles sociétés).
  void applyMarket(MarketSnapshot m) {
    if (m.sessionDate.compareTo(market.sessionDate) <= 0) return;
    market = m;
    city = city.copyWith(prices: {for (final c in m.companies) c.symbol: c.price, ...city.prices});
    _changed();
  }

  void _load() {
    city = CityState.fresh(companies);
    final fresh = city.prices;
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      savings = (j['savings'] as num).toDouble();
      stars = (j['stars'] as Map).map((k, v) => MapEntry(k as String, v as int));
      seenIntro = (j['seenIntro'] as List).cast<int>().toSet();
      final saved = CityState.fromJson((j['city'] as Map).cast());
      city = saved.copyWith(prices: {...fresh, ...saved.prices});
      days = (j['days'] as List).cast<String>().toSet();
      quiz = (j['quiz'] as Map).map((k, v) => MapEntry(int.parse(k as String), v as int));
      cards = (j['cards'] as List).cast<String>();
      pacoDiscret = j['pacoDiscret'] as bool? ?? false;
    } catch (_) {
      // Sauvegarde illisible (ancienne version) : on repart proprement plutôt que de planter.
    }
  }

  Map<String, dynamic> toJson() => {
        'savings': savings,
        'stars': stars,
        'seenIntro': seenIntro.toList(),
        'city': city.toJson(),
        'days': days.toList(),
        'quiz': quiz.map((k, v) => MapEntry('$k', v)),
        'cards': cards,
        'pacoDiscret': pacoDiscret,
      };

  /// Sauvegarde groupée : au plus une écriture par seconde, quel que soit le nombre de coups.
  void _changed() {
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), flush);
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    await _prefs.setString(_key, jsonEncode(toJson()));
  }

  // ---- Progression ----
  int cityStars(int c) => content.levelsOf(c).fold(0, (n, l) => n + (stars[l.id] ?? 0));
  bool cityValidated(int c) => cityStars(c) >= 5 && (quiz[c] ?? 0) >= 2;
  bool cityUnlocked(int c) => c == 1 || cityValidated(c - 1);
  bool levelUnlocked(LevelDef l) => cityUnlocked(l.city) && (l.index == 1 || (stars['c${l.city}-l${l.index - 1}'] ?? 0) > 0);
  int get citiesDone => content.cities.where((c) => cityValidated(c.n)).length;
  int get score => scorePaco(city, companies, days.length);

  String get title {
    final done = citiesDone;
    if (done >= 15 && score >= goatScore) return 'GOAT de la BRVM';
    if (done >= 9) return 'Investisseur Patient';
    if (done >= 4) return 'Actionnaire Moyen';
    return 'Actionnaire Débutant';
  }

  /// Entreprises des pays dont une ville est débloquée.
  List<Company> get unlockedCompanies {
    final countries = content.cities.where((c) => cityUnlocked(c.n)).map((c) => c.country).toSet();
    return companies.where((c) => countries.contains(c.country)).toList();
  }

  void markIntroSeen(int c) {
    seenIntro.add(c);
    _changed();
  }

  /// Niveau gagné : épargne, étoiles, et 1 séance de bourse dans Ma Ville.
  ({double cashGained, EventCard event, bool ago}) winLevel(LevelDef l, int newStars, double earned) {
    final step = advance(city, companies, 2026);
    city = step.state;
    savings += earned + step.cashGained;
    stars[l.id] = newStars > (stars[l.id] ?? 0) ? newStars : (stars[l.id] ?? 0);
    days.add(DateTime.now().toIso8601String().substring(0, 10));
    for (final e in city.holdings.entries) {
      if (city.seance - e.value.since >= 10 && !cards.contains(e.key)) cards.add(e.key);
    }
    _changed();
    return (cashGained: step.cashGained, event: step.event, ago: step.ago);
  }

  /// Quiz : meilleur score gardé ; carte offerte pour un sans-faute.
  String? finishQuiz(int c, int score) {
    quiz[c] = score > (quiz[c] ?? 0) ? score : (quiz[c] ?? 0);
    String? card;
    if (score == 3) {
      final country = content.cities[c - 1].country;
      final pool = companies.where((x) => !cards.contains(x.symbol)).toList();
      final local = pool.where((x) => x.country == country).toList();
      final list = local.isNotEmpty ? local : pool.where(unlockedCompanies.contains).toList();
      if (list.isNotEmpty) {
        card = list[(days.length + c * 7) % list.length].symbol;
        cards.add(card);
      }
    }
    _changed();
    return card;
  }

  bool buyOne(String symbol) {
    final r = buy(city, symbol, 1, savings);
    if (r == null) return false;
    city = r.state;
    savings = r.cash;
    _changed();
    return true;
  }

  double? sellOne(String symbol) {
    final r = sell(city, symbol, 1, savings);
    if (r == null) return null;
    city = r.state;
    savings = r.cash;
    _changed();
    return r.gain;
  }

  void saveFeedback(int c, TesterFeedback f) {
    feedback[c] = f;
    _changed();
  }

  void setPacoDiscret(bool v) {
    pacoDiscret = v;
    _changed();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
