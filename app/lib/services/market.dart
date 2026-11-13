// Cours du jour : servis par le worker paco-market depuis le cache Cloudflare.
// Hors ligne ou en cas d'erreur, le jeu garde la dernière copie valide, puis l'instantané intégré.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/content.dart';

/// URL fixée à la compilation : --dart-define=PACO_MARKET_URL=https://paco-market.<compte>.workers.dev/market/latest
const marketUrl = String.fromEnvironment('PACO_MARKET_URL');
const _cacheKey = 'paco.market.v1';

MarketSnapshot? _parse(String body) {
  try {
    final m = MarketSnapshot.fromJson((jsonDecode(body) as Map).cast());
    return m.companies.length >= 30 ? m : null; // instantané incomplet : refusé
  } catch (_) {
    return null;
  }
}

/// Dernière copie gardée sur le téléphone, si elle est plus récente que l'instantané intégré.
MarketSnapshot? cachedMarket(SharedPreferences prefs, MarketSnapshot bundled) {
  final raw = prefs.getString(_cacheKey);
  final m = raw == null ? null : _parse(raw);
  return m != null && m.sessionDate.compareTo(bundled.sessionDate) > 0 ? m : null;
}

/// Récupère les cours du jour ; une seule tentative, courte, sans bloquer le jeu.
Future<MarketSnapshot?> fetchMarket(SharedPreferences prefs, {http.Client? client}) async {
  if (marketUrl.isEmpty) return null;
  final c = client ?? http.Client();
  try {
    final res = await c.get(Uri.parse(marketUrl)).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final body = utf8.decode(res.bodyBytes);
    final m = _parse(body);
    if (m != null) await prefs.setString(_cacheKey, body);
    return m;
  } catch (_) {
    return null;
  } finally {
    if (client == null) c.close();
  }
}
