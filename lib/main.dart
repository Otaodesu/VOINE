import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mime/mime.dart';
// import 'package:open_filex/open_filex.dart'; 2025-03-01 ビルドエラーのため。ライブラリのバグかも
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'favorability_gauge.dart';
import 'launch_chrome.dart';
import 'replayer.dart';
import 'synthesizeSerif.dart'; // これで自作のファイルを行き来できるみたい.
import 'text_dictionary_editor.dart';
import 'ui_dialog_classes.dart';

// 真っ赤ならターミナルでflutter pub get.

void main() {
  // 日本時間を適用して、それからMyAppウィジェットを起動しにいく.
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    // 『【Flutter】Androidでフォントが中華フォントになってしまう問題の原因と解決方法』
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('ja', 'JP')],
    home: const ChatPage(),
  );
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  List<types.Message> _messages = [];

  List<Widget> _characterSelectButtons = []; // 話者選択ボタンを格納する.

  // 誰が投稿するのかはこの変数で決まる.
  var _user = const types.User(
    id: '388f246b-8c41-4ac1-8e2d-5d79f3ff56d9',
    firstName: 'ずんだもん', // デフォルトスピーカー
    lastName: 'ノーマル', // デフォルトスタイル
    updatedAt: 3, // これがspeakerId😫 スタイル違いも右に表示するにはこれしかなかったんだ…！.
  );

  final _synthesizerChan = LunarSpecSynthesizer(); // 音声合成を担当するシンセサイザーちゃん爆誕。
  late final AudioReplayManager _playerKun; // 再再生を担当するプレーヤーくんは仮設状態。あとで初期化する。

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    final loadedMessages = await loadDefaultMessagesOrResume();
    setState(() {
      _messages = loadedMessages;
    });

    WidgetsBinding.instance.addObserver(this); // didChangeAppLifecycleStateのため

    _loadSpeakerSelectButtons(); // 話者選択ボタンを準備する.

    _playerKun = AudioReplayManager(
      returnBorrowedMessage: (types.Message received) {
        print('😂メッセージID: ${received.id}、おかえり…！');
        _addMessage(received);
      },
    );

    _sequentialSynthesizeDaemon(); // Draemonではない.
  }

  // クルクルが表示されているmessageを常時探して音声合成する。
  void _sequentialSynthesizeDaemon() async {
    while (true) {
      // 表示上の上から順に探す。BSはBeforeSynthesize🙄
      final indexBS = _messages.lastIndexWhere(((element) => element.status == types.Status.sending));

      if (indexBS == -1) {
        await Future.delayed(const Duration(seconds: 1));
        continue; // 無限ループしてチェックを続ける
      }

      final targetMessageBS = _messages[indexBS];

      // types.ImageMessageなどからは音声合成できないので、.seenに書き換えて処理したことにする。禍根: 勝手にseenになってしまう！
      if (targetMessageBS is! types.TextMessage) {
        final updatedMessage = (targetMessageBS).copyWith(status: types.Status.seen);
        setState(() {
          _messages[indexBS] = updatedMessage;
        });
        print('👺音声合成デーモンが${targetMessageBS.toString()}を勝手にseenにしました！');
        continue;
      }

      final targetMessageId = _messages[indexBS].id; // 音声合成している隙にメッセージのindexが変わるかもしれないのでIDで追尾する

      late final Map<String, dynamic> audioQuery; // 💡あとで必ず代入する

      // メッセージにAudioQueryがすでに格納されている場合はそれを使って生成する。これでzrprojを外部で改造して話速を変えたりできるようになる
      if (targetMessageBS.metadata?['query'] is Map<String, dynamic>) {
        audioQuery = targetMessageBS.metadata?['query']; // 👻: もしAudioQuery以外が入っていたらクラッシュするがなんもチェックしてない！
        await _synthesizerChan.synthesizeFromAudioQuery(
          query: audioQuery,
          speakerId: targetMessageBS.author.updatedAt ?? 3,
          textForDisplay: targetMessageBS.text,
        );
      } else {
        audioQuery = await _synthesizerChan.synthesizeFromText(
          text: targetMessageBS.text,
          speakerId: targetMessageBS.author.updatedAt ?? 3,
        );
      }
      // ↕音声合成完了までの時間経過あり.
      final indexAS = _messages.indexWhere((element) => element.id == targetMessageId); // AfterSynthesize.
      if (indexAS == -1) {
        print('🤯メッセージが…なくなってる！');
        continue;
      }

      // AudioQueryを.metadataに格納し、合成完了と分かる表示に更新していく.
      final updatedMetadataAS = _messages[indexAS].metadata ?? {}; // もとのmetadataを保持👻 nullならnull合体演算子でMapを作成😶.
      updatedMetadataAS['query'] = audioQuery; // キーの変更時は要注意☢.

      final updatedMessageAS = (_messages[indexAS]).copyWith(status: types.Status.sent, metadata: updatedMetadataAS);
      setState(() {
        _messages[indexAS] = updatedMessageAS;
      });

      print('😆$targetMessageIdの音声合成が正常に完了しました!');
    } // 待ちリストなんていらんかったんや！
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // didChangeAppLifecycleStateのため
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('🤖ライフサイクル: $state');
    if (state == AppLifecycleState.inactive) {
      // 次回起動時に続きから編集（レジューム）できるようにオートセーブする
      // .pausedや.detachedはタスクマネージャーから終了させたとき発動しなかったので.inactiveにした
      saveMessagesForResume(_messages);
    }
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  // 画面左下の添付ボタンで動き出す関数.
  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // これ追加するだけでスクロールし始めた。見直したぜFlutter(カッコがやばい).
      builder:
          (BuildContext context) => SafeArea(
            child: SizedBox(
              // SizedBoxで領域を指定してその中全面にSingleChildScrollViewを表示する。よくできてる！(カッコがやばい).
              height: MediaQuery.of(context).size.height * 0.8,
              child: Scrollbar(
                radius: const Radius.circular(10),
                child: SingleChildScrollView(
                  // 最上段に突き当たると自動で閉じてほしい欲が出てくる。RefreshIndicatorでpopを発動すればできそう.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _characterSelectButtons, // 最終的に表示する中身がこれ。先に準備できている必要がある.
                  ),
                ),
              ),
            ),
          ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      _addMessage(message);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(imageQuality: 70, maxWidth: 1440, source: ImageSource.gallery);

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  // キャラ選択から選んだとき呼び出す関数.
  void _handleCharacterSelection({required types.User whoAmI}) async {
    setState(() {
      _user = whoAmI;
    });
    print('ユーザーID${_user.id}、話者ID${_user.updatedAt}の姓${_user.firstName}名${_user.lastName}さんになりました');

    incrementSpeakerUseCount(speakerId: whoAmI.updatedAt ?? -1); // 禍根: ID-1の使用履歴が増えるかも.
    _loadSpeakerSelectButtons(); // 好感度ゲージを更新するためにリロードする.
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index = _messages.indexWhere((element) => element.id == message.id); // Idからメッセージの位置を逆引きしてる.
          final updatedMessage = (_messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          ); // 特定のプロパティだけ上書きしつつコピーしてる.

          setState(() {
            _messages[index] = updatedMessage; // これできるのかよ！🤯コロンブスの卵というかなんというか.
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index = _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage = (_messages[index] as types.FileMessage).copyWith(isLoading: null);

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }
      // await OpenFilex.open(localPath); 2025-03-01 ビルドエラーのため
    } else if (message is types.TextMessage) {
      print('ふきだしタップを検出。メッセージIDは${message.id}。再再生してみます！');
      final isWavStillPlayable = await _playerKun.replayFromMessage(message, false); // 再生してみて成否を取得.
      if (!isWavStillPlayable) {
        if (message.status == types.Status.sending) {
          await Fluttertoast.showToast(msg: 'まだ合成中です🤔');
        }
        // 再合成するためにsendingのマークをつけてdaemonに見つけてもらう
        final updatedMessage = (message).copyWith(status: types.Status.sending);
        final index = _messages.indexWhere(((element) => element.id == message.id));
        if (index == -1) {
          return;
        }
        setState(() {
          _messages[index] = updatedMessage;
        });
      }
    }
  }

  // ふきだしを長押ししたときここが発動.
  void _handleMessageLongPress(BuildContext _, types.Message message) {
    print('メッセージ${message.id}が長押しされたのを検出しました😎型は${message.runtimeType}です');

    if (message is! types.TextMessage) {
      print('TextMessage型じゃないので何もしません');
      return; // あらかじめフィルターする.
    }

    showDialog<String>(
      context: context,
      builder:
          (_) => FukidashiLongPressDialog(
            // ↕操作するまで時間経過あり。この隙にmessageが書き換わってる可能性（合成完了時など）があるのでUUIDを渡す.
            onAddMessageBelowPressed: () => _addMessageBelow(message.id),
            onChangeSpeakerPressed: () => _changeSpeaker(message.id, _user),
            onDeleteMessagePressed: () => _deleteMessage(message.id),
            onPlayAllBelow: () => _playAllBelow(message.id),
            onSynthesizeAllBelow: () => _synthesizeAllBelow(message.id),
            onMoveMessageUpPressed: () => _moveMessageUp(message.id),
            onMoveMessageDownPressed: () => _moveMessageDown(message.id),
          ),
    );
  }

  void _deleteMessage(String messageId) {
    final index = _messages.indexWhere((element) => element.id == messageId);
    setState(() {
      _messages.removeAt(index);
    });
    print('$messageIdを削除しました👻');
  }

  void _moveMessageUp(String messageId) {
    final index = _messages.indexWhere((element) => element.id == messageId);
    if (index + 1 == _messages.length) {
      Fluttertoast.showToast(msg: 'いじわるはやめろなのだ😫');
      return;
    }
    final temp = _messages[index];
    final updatedMessages = _messages;
    updatedMessages[index] = updatedMessages[index + 1];
    updatedMessages[index + 1] = temp;
    setState(() {
      _messages = updatedMessages;
    }); // 結構ボリュームフルになったぞ.
  }

  void _moveMessageDown(String messageId) {
    final index = _messages.indexWhere((element) => element.id == messageId);
    if (index == 0) {
      Fluttertoast.showToast(msg: 'いじわるはやめろなのだ😫');
      return;
    }
    final temp = _messages[index];
    final updatedMessages = _messages;
    updatedMessages[index] = updatedMessages[index - 1];
    updatedMessages[index - 1] = temp;
    setState(() {
      _messages = updatedMessages;
    }); // リスト上を指でスワイプして並べ替えできるUIがほしいよね？それめっちゃわかる😫.
  }

  void _synthesizeAllBelow(String messageId) {
    final index = _messages.indexWhere((element) => element.id == messageId);
    for (var i = index; i >= 0; i--) {
      if (_messages[i] is types.TextMessage) {
        // 再合成するためにsendingにしてデーモンに見つけてもらう
        final updatedMessage = (_messages[i]).copyWith(status: types.Status.sending);
        setState(() {
          _messages[i] = updatedMessage;
        });
      }
    }
  }

  Future<void> _playAllBelow(String messageId) async {
    final index = _messages.indexWhere((element) => element.id == messageId);
    final messagesToLend = _messages.getRange(0, index + 1).toList();
    print('🤯playerくんに一部貸すので_messagesを消します！');
    setState(() {
      _messages.removeRange(0, index + 1);
    });
    await Future.delayed(const Duration(seconds: 1)); // 演出
    await _playerKun.replayFromMessages(messagesToLend);
    // 改造したら_startPlayAll()も揃えること。もしくはここへリレーさせる？
  }

  void _changeSpeaker(String messageId, types.User afterActor) {
    final index = _messages.indexWhere((element) => element.id == messageId);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      id: const Uuid().v4(),
      author: afterActor,
      status: types.Status.sending,
      metadata: null, // audioQueryは引き継がない。キャッシュにより変更前の音声が再生されてしまうため😨
    );
    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handlePreviewDataFetched(types.TextMessage message, types.PreviewData previewData) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(previewData: previewData);

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _addMessageBelow(String messageId) async {
    final inputtedText = await showEditingDialog(context, '${_user.firstName}（${_user.lastName}）');
    // ↕時間経過あり.
    final index = _messages.indexWhere((element) => element.id == messageId);
    if (inputtedText == null || index == -1) {
      await Fluttertoast.showToast(msg: 'ぬるぽ');
      return;
    }

    final splitTexts = await splitTextIfLong(inputtedText);
    for (var pickedText in splitTexts) {
      final textMessage = types.TextMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: pickedText,
        status: types.Status.sending,
      );
      setState(() {
        _messages.insert(index, textMessage);
      });
    }
  }

  // 送信ボタン押すときここが動く.
  void _handleSendPressed(types.PartialText message) async {
    final splitTexts = await splitTextIfLong(message.text); // もともとPartialText.text以外投稿に反映されてないからいいよね😚.
    for (var pickedText in splitTexts) {
      final textMessage = types.TextMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: pickedText,
        status: types.Status.sending,
      );
      _addMessage(textMessage); // 最新メッセージは[0]なのでこれでヨシ.
    }
  }

  // User型しか入ってこない。さあどうしよう.
  void _handleAvatarTap(types.User tappedUser) {
    print('$tappedUserのアイコンがタップされました');
    setState(() {
      _user = tappedUser;
    });
    // 期待するのは本家VOICEVOXと同じ動作。そんなんわかっとるわい🤧！.
    // でも直近に使ったスタイルをすぐ取り出せるから便利では？ほらほら.
  }

  // 選択ボタンウィジェットを準備する。好感度ゲージを更新したい場合はここを動かすこと.
  void _loadSpeakerSelectButtons() async {
    final textButtons = <TextButton>[];
    final charactersDictionary = await loadCharactersDictionary();

    // 二重ループでリストにボタンを追加しまくる。これはヤバいでPADの速度じゃありえん.
    // 起動時にリストを作って準備しておく…ことになった。毎回テイクアウトではコストがかさむため。←今は何言ってるか分かるけども….
    for (final pickedCharacter in charactersDictionary) {
      for (final pickedUser in pickedCharacter) {
        textButtons.add(
          TextButton(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${pickedUser.firstName}（${pickedUser.lastName}）'),
                Transform.flip(flipX: true, child: await takeoutSpeakerFavorabilityGauge(pickedUser.updatedAt ?? -1)),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _handleCharacterSelection(whoAmI: pickedUser); // キャラ選択時にはこの関数が動く.
            },
          ),
        );
      }
    }

    // もとからあったフォト、ファイル、キャンセルのボタンも追加する.
    textButtons.add(
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          _handleImageSelection();
        },
        child: const Align(alignment: AlignmentDirectional.centerStart, child: Text('Photo')),
      ),
    );
    textButtons.add(
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          _handleFileSelection();
        },
        child: const Align(alignment: AlignmentDirectional.centerStart, child: Text('File')),
      ),
    );
    textButtons.add(
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Align(alignment: AlignmentDirectional.centerStart, child: Text('Cancel')),
      ),
    );

    _characterSelectButtons = textButtons;
  }

  // メッセージを空にする.
  void _deleteAllMessages() {
    setState(() {
      _messages = [];
    });
  }

  // プロジェクトのエクスポート.
  void _showProjectExportView() {
    final exportingText = jsonEncode(_messages);

    showDialog<String>(
      context: context,
      builder:
          (_) => AlternateOfKakidashi(
            whatYouWantShow: exportingText,
            whatYouWantSetTitle: 'はいっ、書き出した！🤔',
            whatWillFileExtensionBe: 'zrproj',
          ),
    );
    // 3MBを超えるような長大プロジェクトの書き出しには2sec～時間がかかる。jsonEncodeは120ms程度だったのでUI処理が大半を占めてそう
    // AlternateOfKakidashiでいきなり表示せず非同期にsetStateするようにすれば高速化するかも。statefulWidgetへの変更が必要なので他のUIを考えたほうが楽かも
  }

  // テキストとしてエクスポート.
  void _showTextExportView() {
    final exportingText = makeText(_messages);

    // ↓async関数にする場合if(mounted)が必要になるかも.
    showDialog<String>(
      context: context,
      builder:
          (_) => AlternateOfKakidashi(
            whatYouWantShow: exportingText,
            whatYouWantSetTitle: 'はいっ、書き出した！🤔',
            whatWillFileExtensionBe: 'txt',
          ),
    );
  }

  // プロジェクトのインポート。ノリで作ってしまったが絶対あぶない動き方。ヤバイ火遊び🎩🧢.
  void _letsImportProject() async {
    final whatYouInputted = await showEditingDialog(context, 'ずんだ');
    // ↕時間経過あり.
    final updatedMessages = combineMessagesFromJson(whatYouInputted, _messages);
    if (updatedMessages == _messages) {
      await Fluttertoast.showToast(msg: '😿これは.zrprojではありません！\n: $whatYouInputted');
      return;
    }
    setState(() {
      _messages = updatedMessages;
    });
    await Fluttertoast.showToast(msg: '😹インポートに成功しました！！！');
  }

  void _handleHamburgerPressed() {
    showDialog<String>(
      context: context,
      builder:
          (_) => HamburgerMenuForChat(
            onDeleteAllMessagesPressed: _deleteAllMessages,
            onExportProjectPressed: _showProjectExportView,
            onExportAsTextPressed: _showTextExportView,
            onImportProjectPressed: _letsImportProject,
            onEditTextDictionaryPressed: () => showDictionaryEditPage(context),
          ),
    );
  }

  /// 先頭から順番に再生する関数。改造したら_playAllBelowも揃えること。状態管理？😌そんなものはない.
  void _startPlayAll() async {
    final messagesToLend = _messages; // 些細な問題🙃: 再生中の変更が適用されない。合成完了とか.
    print('🤯playerくんに全部貸すので_messagesを空にします！'); // タイミングが前後すると消えることになる
    setState(() {
      _messages = [];
    });
    await Future.delayed(const Duration(seconds: 1)); // 演出
    await _playerKun.replayFromMessages(messagesToLend);
  }

  void _stopPlayAll() {
    _playerKun.stop(); // すぐさま止まります！.
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBarForChat(onPlayTap: _startPlayAll, onStopTap: _stopPlayAll, onHamburgerPress: _handleHamburgerPressed),
    body: Chat(
      messages: _messages,
      onAttachmentPressed: _handleAttachmentPressed,
      onMessageTap: _handleMessageTap,
      onMessageLongPress: _handleMessageLongPress,
      onAvatarTap: _handleAvatarTap,
      onPreviewDataFetched: _handlePreviewDataFetched,
      onSendPressed: _handleSendPressed,
      showUserAvatars: true,
      showUserNames: true,
      user: _user,
      theme: const DefaultChatTheme(seenIcon: Text('read', style: TextStyle(fontSize: 10.0))),
      l10n: ChatL10nEn(inputPlaceholder: '${_user.firstName}（${_user.lastName}）'),
    ),
  );
}
