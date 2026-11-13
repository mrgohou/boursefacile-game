import 'package:material_ui/material_ui.dart';

import 'data/player_repository.dart';
import 'ui/paco_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PacoApp(repository: LocalPlayerRepository()));
}
