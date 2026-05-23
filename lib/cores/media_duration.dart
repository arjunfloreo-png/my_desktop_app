import 'package:media_kit/media_kit.dart';

Future<Duration?> getMediaDuration(String videoUrl) async {
  Player? player;
  try {
    player = Player();
    await player.open(Media(videoUrl), play: false);
    await player.play();  // ← must play to get duration
    
    final dur = await player.stream.duration
        .firstWhere((d) => d.inSeconds > 0)
        .timeout(const Duration(seconds: 15));
    
    await player.stop();
    print('✓ media duration: $dur');
    return dur;
  } catch (e) {
    print('✗ media duration error: $e');
    return null;
  } finally {
    await player?.dispose(); // ← always dispose
  }
}