import 'package:flutter_test/flutter_test.dart';
import 'package:paco_bourse/audio/game_audio.dart';

void main() {
  test(
    'silent service initializes repeatedly without resetting preferences',
    () async {
      final audio = SilentGameAudio();
      expect(audio.ready, isFalse);
      expect(audio.musicEnabled, isTrue);
      expect(audio.sfxEnabled, isTrue);
      await audio.setMusicEnabled(false);
      await audio.initialize();
      await audio.initialize();
      expect(audio.ready, isTrue);
      expect(audio.musicEnabled, isFalse);
      expect(audio.sfxEnabled, isTrue);
      audio.dispose();
    },
  );
  test(
    'scene, lifecycle and independent toggles remain usable without plugins',
    () async {
      final audio = SilentGameAudio();
      var notifications = 0;
      audio.addListener(() => notifications++);
      await audio.initialize();
      await audio.setScene('puzzle');
      audio.pause();
      expect(audio.paused, isTrue);
      await audio.setSfxEnabled(false);
      audio.resume();
      audio.play('match', chain: 3);
      expect(audio.paused, isFalse);
      expect(audio.scene, 'puzzle');
      expect(audio.musicEnabled, isTrue);
      expect(audio.sfxEnabled, isFalse);
      expect(notifications, 2);
      await expectLater(audio.setScene('unknown'), throwsArgumentError);
      audio.dispose();
      await audio.initialize();
      await audio.setMusicEnabled(false);
      expect(audio.ready, isFalse);
      expect(notifications, 2);
    },
  );
}
