/// 音声合成パラメータをまとめる型。プリセット機能とか作るときに便利そうなので準備しておいた。
class VoiceParams {
  double speedScale;
  double pitchScale;
  double intonationScale;
  double volumeScale;
  double prePhonemeLength;
  double postPhonemeLength;

  VoiceParams({
    required this.speedScale,
    required this.pitchScale,
    required this.intonationScale,
    required this.volumeScale,
    required this.prePhonemeLength,
    required this.postPhonemeLength,
  });
}
