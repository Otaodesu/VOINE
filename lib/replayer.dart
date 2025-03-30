import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';

import 'voicevox_controller.dart' show navigateWavCache;

// メッセージ再再生関連を一挙に制御するクラスまた作りかえたった！.
class AudioReplayManager {
  AudioReplayManager({required this.returnBorrowedMessage});

  // 連続再生時の非表示/再表示を「メッセージをこのクラスに貸す/UIに再表示するタイミングで返してもらう」というやり取りで表現してみた
  final Function(types.Message) returnBorrowedMessage; // コールバックで返却する
  final List<types.Message> _holdingMessages = []; // mainの_messagesと同じ順番、つまり末尾から再生、返却する

  List<AudioPlayer> _playerObjects = []; // 単発再生の連打に対応するため複数のプレーヤーインスタンスを格納する🫨.

  /// メッセージ単発を再生するメソッド。再生できたらtrueを返す。willWaitで再生完了まで待つ。
  Future<bool> replayFromMessage(types.TextMessage message, bool willWait) async {
    if (message.metadata?['query'] == null) {
      print('audioQueryがないのでまだ合成していないようです。現場からは以上です。');
      return false;
    }

    final Map<String, dynamic> audioQuery = message.metadata?['query'];
    final wavCache = await navigateWavCache(audioQuery);

    if (wavCache == null) {
      return false;
    }

    _playerObjects.add(AudioPlayer()); // 『[flutter]just_audioで音を再生する』.
    final index = _playerObjects.length - 1; // 連打すると位置がずれるので.last.playとかにしない.
    try {
      await _playerObjects[index].setAudioSource(AudioSource.file(wavCache.path));
      await _playerObjects[index].play();

      if (willWait) {
        // 再生完了まで待つ。ここにfirstWhere出てくるのすっごい奇天烈.
        await _playerObjects[index].playerStateStream.firstWhere(
          (state) => state.processingState == ProcessingState.completed,
        );
      }
    } catch (e) {
      print('キャッチ！🤗$eとのことです。現場からは以上です。');
    }
    return true;
  }

  /// メッセージを連続再生するメソッド。再生開始のタイミングにコールバックで返却する。連打非対応だけどexceptionにはならないのであえて制限していない。あえて。
  Future<void> replayFromMessages(List<types.Message> messages) async {
    var wasToastShown = false; // WAVが再生できなかったとき、1回だけトーストを表示するためのフラグ

    print('😸${messages.length}件のメッセージ、しかと受け取りました');
    _holdingMessages.addAll(messages);

    while (_holdingMessages.isNotEmpty) {
      final targetMessage = _holdingMessages.last;
      _holdingMessages.removeLast();
      print('😹メッセージID: ${targetMessage.id}をお返しします…！');
      returnBorrowedMessage(targetMessage);

      if (targetMessage is types.TextMessage) {
        final isStillPlayable = await replayFromMessage(targetMessage, true);
        // ↕️時間経過あり
        if (!isStillPlayable && !wasToastShown) {
          await Fluttertoast.showToast(msg: '🔰ふきだしをタップして音声合成してください');
          wasToastShown = true;
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 1000)); // 演出。ImageMessageと次のセリフに間を設ける
      }
    }
  }

  /// すべてストップするメソッド.
  void stop() {
    // for-inだとコピーに対する操作になるのでstopが効かない。直接指定するとヨシ😸.
    for (var i = 0; i < _playerObjects.length; i++) {
      _playerObjects[i].dispose();
    }
    _playerObjects = [];

    // 借りたメッセージをすべて返却する
    while (_holdingMessages.isNotEmpty) {
      print('😹メッセージID: ${_holdingMessages.last.id}をお返しします…！');
      returnBorrowedMessage(_holdingMessages.last); // 再生中に.stopによって空になっているかもしれないので注意
      _holdingMessages.removeLast();
    }
  }
}
