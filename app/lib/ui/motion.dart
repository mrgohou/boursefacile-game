import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Animations d'ambiance (passants, pulsations) : coupées pendant les tests automatiques
/// et quand le téléphone demande de réduire les animations (accessibilité).
final bool _underTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

bool ambientMotion(BuildContext context) => !_underTest && !MediaQuery.of(context).disableAnimations;
