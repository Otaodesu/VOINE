import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'text_dictionary_editor.dart';
import 'voicevox_controller.dart';

class LunarSpecSynthesizer {
  LunarSpecSynthesizer() {
    _initialize();
  }

  final _voicevox = VoicevoxFlutterController();
  late AudioHandler _audioHandler;
  bool isFirstPlay = true; // 起動後初回だけ.playするため

  /// 音声合成済みキャッシュから再生する関数。できたらtrueを返す
  Future<bool> _playFromCache(Map<String, dynamic> query, String textForDisplay) async {
    final wavCache = await navigateWavCache(query);

    if (wavCache == null) {
      return false; // キャッシュが存在しなかったのでfalse
    }

    await _audioHandler.addQueueItem(MediaItem(id: wavCache.path, title: textForDisplay, album: '音声合成中プレイリスト'));

    if (isFirstPlay) {
      await _audioHandler.play();
      isFirstPlay = false;
    }

    return true; // プレイリストに追加できたのでtrue
  }

  /// 😆音声合成を行う主役のメソッド。AudioQueryを返す.
  Future<Map<String, dynamic>> synthesizeFromText({required String text, required int speakerId}) async {
    final serif = await convertTextToSerif(text); // 読み方辞書を適用する.

    final queryAsString = await _voicevox.textToAudioQuery(text: serif, styleId: speakerId); // AudioQueryを生成してもらう

    final Map<String, dynamic> audioQuery = jsonDecode(queryAsString);

    final isCached = _playFromCache(audioQuery, text);
    if (await isCached) {
      return audioQuery; // キャッシュから再生できたようなのでここで完了
    }

    await _voicevox.audioQueryToWav(audioQuery: queryAsString, styleId: speakerId); // 音声を生成してキャッシュに保存してもらう
    // ↕️時間経過あり
    await _playFromCache(audioQuery, text);
    return audioQuery;
  }

  /// 😋AudioQuery以外が入ってくるとクラッシュする。
  Future<void> synthesizeFromAudioQuery({
    required Map<String, dynamic> query,
    required int speakerId,
    required String textForDisplay, // 通知欄の再生パネルに表示するため
  }) async {
    final isCached = _playFromCache(query, textForDisplay);
    if (await isCached) {
      return; // キャッシュから再生できたようなのでここで完了
    }

    await _voicevox.audioQueryToWav(audioQuery: jsonEncode(query), styleId: speakerId); // 音声を生成してキャッシュに保存してもらう
    // ↕️時間経過あり
    await _playFromCache(query, textForDisplay);
  }

  void _initialize() async {
    _audioHandler = await AudioService.init(
      builder: () => _MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.voine.channel.audioForSynthesizer',
        androidNotificationChannelName: '音声合成中プレイリストの操作パネル',
        androidNotificationOngoing: true,
      ),
    );

    print('${DateTime.now()}😋NativeVoiceServiceを起動します…');
    await _voicevox.initialize(); // voicevox_flutterを起動する
    print('${DateTime.now()}🥰NativeVoiceServiceが起動しました！');
  }
}
// （下ほど新しいコメント）.
// .setAudioSourceするとその都度[0]から再生になる（?付き引数になっている）.
// プレイリストが空のとき.playするとプレイリストに追加されるまで待つモードになる。アプリの外からは再生中として扱われるので待ちかねてYouTube見始めると追加しても鳴り始めない.
// ユーザーが入力したものは「テキスト」、音声合成に最適化したものは「セリフ」。…もうごっちゃです.
// 読み方辞書を用いたテキスト→セリフ変換をこっちに持ってきた。辞書の変更がリアルタイムに反映されるようになるが流用性は薄れる.
// MeteorSpecSynthesizer. 語感のカッコよさだけで命名
// 推奨環境はSnapdragon865、RAM6GB。長文の分割合成時にかろうじて追いつかずに生成できる
// service.dartを改造して、モデルを必要になったタイミングでRAMにロードするようにした。生成中2.5GBが1.2GBまで軽量化！

// Perfetto UIでCPUコアの駆動状況が見れる。以下はcpuNumThreads: 4、同時オーダー数: 1での音声合成してそうなコア数
// TensorG1 (big2+mid2+little4)… big2+mid2
// Snapdragon865 (big1+mid3+little4)… big1+mid3
// Snapdragon765G (big1+mid1+little6)… big1(だけ！？)
// Snapdragon680 (mid4+little4)… mid4
// Snapdragon720G (mid2+little6)… mid2(だけ！？)
// Snapdragon450 (mid8)… mid4
// Snapdragon808 (mid2+little4)… mid2+little2
// Snapdragon820 (mid2+little2)… mid2

// キャッシュを活用するならmessageにaudioQueryが格納されているか否か、生成済みのwavがキャッシュされているか否かによって4パターンの動作が要求される。
// A: クエリがない、キャッシュがない （入力欄から送信したとき）
// B: クエリがない、キャッシュがある （入力欄から送信したテキストが以前生成したテキストと偶然ダブっていたとき）
// C: クエリがある、キャッシュがない （他のデバイスで編集したzrprojをインポートしたとき。これに対応すれば無理やり話速を変更することも可能になる）
// D: クエリがある、キャッシュがある （《この先すべてを音声合成する》を行ったとき）
// これらパターンのうち、クエリがあるかはmain側で分岐、キャッシュから再生するかはこのクラス側で分岐するようにしてみた。
// 読み方辞書の変更を反映したいときは《話者を変更する》で一応できるはず…🫠

// ひさびさにこのアプリを引っ張り出すも当然のようにFlutterの破壊的変更でビルドできず。空のサンプルアプリから作り直してたらなんとVOICEVOX Core 0.16.0にAndroid向けビルドが出てるのを発見！
// voicevox_flutterを改造して、ついに ずんだもん（へろへろ） に対応できた！

//
// ついにaudio_serviceを導入し、通知バーから一時停止/スキップを行えるようにした
// https://github.com/suragch/flutter_audio_service_demo/blob/master/final/lib/services/audio_handler.dart (8ae2d18) より。まるごと引っ張ってきた
class _MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer(); // just_audioをラッピングして動作を監視することでOSとの連携が可能になる…という解釈…？
  final _playlist = ConcatenatingAudioSource(children: []);

  _MyAudioHandler() {
    _loadEmptyPlaylist();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
  }

  Future<void> _loadEmptyPlaylist() async {
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      print('Playlist initialization error: $e');
    }
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (_player.playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
          ],
          androidCompactActionIndices: const [0, 1, 2], // controlsの項目数減らしてみたのでそれに追従
          systemActions: const {MediaAction.seek},
          processingState:
              const {
                ProcessingState.idle: AudioProcessingState.idle,
                ProcessingState.loading: AudioProcessingState.loading,
                ProcessingState.buffering: AudioProcessingState.buffering,
                ProcessingState.ready: AudioProcessingState.ready,
                ProcessingState.completed: AudioProcessingState.completed,
              }[_player.processingState]!,
          playing: _player.playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          queueIndex: event.currentIndex,
        ),
      );
    });
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      var index = _player.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices!.indexOf(index);
      }
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices!.indexOf(index);
      }
      mediaItem.add(playlist[index]);
    });
  }

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((SequenceState? sequenceState) {
      final sequence = sequenceState?.effectiveSequence;
      if (sequence == null || sequence.isEmpty) return;
      final items = sequence.map((source) => source.tag as MediaItem);
      queue.add(items.toList());
    });
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    // manage Just Audio
    final audioSource = AudioSource.file(
      mediaItem.id, // これがファイルパス
      tag: mediaItem,
    );
    await _playlist.add(audioSource);

    // notify system
    final newQueue = queue.value..add(mediaItem);
    queue.add(newQueue);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    // manage Just Audio
    await _playlist.removeAt(index);

    // notify system
    final newQueue = queue.value..removeAt(index);
    queue.add(newQueue);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    if (_player.shuffleModeEnabled) {
      index = _player.shuffleIndices![index];
    }
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  // アプリを閉じたときに通知パネルに残らないようにする。YouTube Musicと同じ動きにしたい
  @override
  Future<void> onTaskRemoved() {
    _player.dispose();
    return super.onTaskRemoved();
  }
}
