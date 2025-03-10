import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// 言い訳: UIはどんどん込み入ってくると分かったので実際の処理と別にしたほうが理解しやすいかもと思ったんです.

// こっちのダイアログにもVoidCallbackを導入し、75行を98行にした。main側は半分に省略できたのでヨシ！😭.
class FukidashiLongPressDialog extends StatelessWidget {
  const FukidashiLongPressDialog({
    super.key,
    required this.onDeleteMessagePressed,
    required this.onMoveMessageUpPressed,
    required this.onMoveMessageDownPressed,
    required this.onPlayAllBelow,
    required this.onSynthesizeAllBelow,
    required this.onAddMessageBelowPressed,
    required this.onChangeSpeakerPressed,
  });

  final VoidCallback onDeleteMessagePressed;
  final VoidCallback onMoveMessageUpPressed;
  final VoidCallback onMoveMessageDownPressed;
  final VoidCallback onPlayAllBelow;
  final VoidCallback onSynthesizeAllBelow;
  final VoidCallback onAddMessageBelowPressed;
  final VoidCallback onChangeSpeakerPressed;

  @override
  Widget build(BuildContext context) => SimpleDialog(
        title: const Text('アクション選択'),
        surfaceTintColor: Colors.green, // ずんだ色にしてみた.
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.of(context).pop();
              onDeleteMessagePressed();
            },
            child: const ListTile(
              leading: Icon(Icons.delete_rounded),
              title: Text('削除する'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.of(context).pop();
              onMoveMessageUpPressed();
            },
            child: const ListTile(
              leading: Icon(Icons.move_up_rounded),
              title: Text('上に移動する'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.of(context).pop();
              onMoveMessageDownPressed();
            },
            child: const ListTile(
              leading: Icon(Icons.move_down_rounded),
              title: Text('下に移動する'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.of(context).pop();
              onPlayAllBelow();
            },
            child: const ListTile(
              leading: Icon(Icons.playlist_play_rounded),
              title: Text('ここから連続再生する'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.of(context).pop();
              onSynthesizeAllBelow();
            },
            child: const ListTile(
              leading: Icon(Icons.graphic_eq_rounded),
              title: Text('この先すべてを音声合成する'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.of(context).pop();
              onAddMessageBelowPressed();
            },
            child: const ListTile(
              leading: Icon(Icons.add_comment_rounded),
              title: Text('セリフを追加する'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.of(context).pop();
              onChangeSpeakerPressed();
            },
            child: const ListTile(
              leading: Icon(Icons.social_distance_rounded), // 😳.
              title: Text('話者を変更する\n（入力欄の話者へ）'),
            ),
          ),
        ],
      );
}

// 本家のchat.dartを見た。mainがスッキリしていい感じ。なんていう書き方かは知らん.
// TapとPressには明確な使い分けがある的な記載を見たような見てないような….
class AppBarForChat extends StatelessWidget implements PreferredSizeWidget {
  const AppBarForChat({
    super.key,
    this.onPlayTap,
    this.onStopTap,
    this.onHamburgerPress, // 🍔はプレスするものだからPress.
  });

  final VoidCallback? onPlayTap;
  final VoidCallback? onStopTap;
  final VoidCallback? onHamburgerPress;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) => AppBar(
        title: const Text('非公式のプロジェクト', style: TextStyle(color: Colors.black54)),
        backgroundColor: Colors.white.withAlpha(230),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20), // 逆に出っ張らせたいんやが？超難しそう？.
            bottomRight: Radius.circular(20),
          ),
        ),
        actions: [
          Tooltip(
            message: '先頭から連続再生する',
            child: IconButton(
              // ←←エディターにアイコンのプレビュー出るのヤバくね！？.
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: onPlayTap,
            ),
          ),
          Tooltip(
            message: '再生を停止する',
            child: IconButton(
              icon: const Icon(Icons.stop_rounded),
              onPressed: onStopTap,
            ),
          ),
          Tooltip(
            message: 'プロジェクトのオプションを表示する',
            child: IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: onHamburgerPress,
            ),
          ),
        ],
      );
  // SliverAppBarにしたいよね😙→2時間経過→ぜんぜんわからん！😫.
  // SliverToBoxAdapter{child: SizedBox{height: 2000,child: Chat()}}}でそれっぽいとこまでいったけど、構造上求めるものはできへんのちゃうか？😨.
}

// ハンバーガーメニュー.
class HamburgerMenuForChat extends StatelessWidget {
  const HamburgerMenuForChat({
    super.key,
    this.onExportProjectPressed,
    this.onExportAsTextPressed,
    this.onDeleteAllMessagesPressed,
    this.onImportProjectPressed,
    this.onEditTextDictionaryPressed,
  });

  final VoidCallback? onExportProjectPressed;
  final VoidCallback? onDeleteAllMessagesPressed;
  final VoidCallback? onExportAsTextPressed;
  final VoidCallback? onImportProjectPressed;
  final VoidCallback? onEditTextDictionaryPressed;

  @override
  Widget build(BuildContext context) => SimpleDialog(
        title: const Text('アクション選択'),
        surfaceTintColor: Colors.green,
        children: [
          SimpleDialogOption(
            onPressed: onExportAsTextPressed,
            child: const ListTile(
              leading: Icon(Icons.list_alt_rounded),
              title: Text('テキストとして書き出す（.txt）'),
            ),
          ),
          SimpleDialogOption(
            onPressed: onExportProjectPressed,
            child: const ListTile(
              leading: Icon(Icons.output_rounded),
              title: Text('プロジェクトを書き出す（.zrproj）'),
            ),
          ),
          SimpleDialogOption(
            onPressed: onImportProjectPressed,
            child: const ListTile(
              leading: Icon(Icons.exit_to_app_rounded),
              title: Text('プロジェクトを読み込む（.zrproj）'),
            ),
          ),
          SimpleDialogOption(
            onPressed: onEditTextDictionaryPressed,
            child: const ListTile(
              leading: Icon(Icons.import_contacts_rounded),
              title: Text('読み方辞書を開く'),
            ),
          ),
          SimpleDialogOption(
            onPressed: onDeleteAllMessagesPressed,
            child: const ListTile(
              leading: Icon(Icons.delete_forever_rounded),
              title: Text('すべて削除する'),
            ),
          ),
        ],
      );
}

// ファイル書き出し機能のかわりに表示することにしたUI😖.
class AlternateOfKakidashi extends StatelessWidget {
  const AlternateOfKakidashi({
    super.key,
    required this.whatYouWantShow,
    required this.whatYouWantSetTitle,
    required this.whatWillFileExtensionBe,
  });

  /// 書き出すテキスト
  final String whatYouWantShow;

  /// タイトル。🤨： ファイルとして共有する際のファイル名になるわけではない
  final String whatYouWantSetTitle;

  /// ファイルとして共有する際の拡張子
  final String whatWillFileExtensionBe;

  void _saveOnClipboard() async {
    await Clipboard.setData(ClipboardData(text: whatYouWantShow));
    await Fluttertoast.showToast(msg: 'クリップボードにコピーしました');
  }

  void _shareAsFile() async {
    // 予言: ファイル名をカスタム可能にしたくなる。そしてファイル名に含まれた "/" で意図しないフォルダに保存してしまう。
    final folderPath = (await getTemporaryDirectory()).path;
    final fileName = '${DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now())}.$whatWillFileExtensionBe';
    final temp = File('$folderPath/$fileName');
    await temp.writeAsString(whatYouWantShow);

    await Share.shareXFiles([XFile(temp.path)]); // 共有ダイアログを表示する
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
          whatYouWantSetTitle,
          overflow: TextOverflow.fade,
          softWrap: false,
        ),
        surfaceTintColor: Colors.green,
        content: SelectableText(
          whatYouWantShow,
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          Tooltip(
            message: 'すべてコピーする',
            child: IconButton(
              onPressed: _saveOnClipboard,
              icon: const Icon(Icons.copy_rounded),
            ),
          ),
          Tooltip(
            message: 'ファイルにして保存する',
            child: IconButton(
              onPressed: _shareAsFile,
              icon: const Icon(Icons.folder_outlined),
            ),
          ),
        ],
      );
} // GoogleKeepへの保存やコピー機能を搭載したがそういう処理はここに書かないはずだったのでは…？🤔.

// 入力ダイアログ。プロジェクトのインポートとかに使う。『ダイアログでもテキスト入力がしたい』🥰.
class TextEditingDialog extends StatefulWidget {
  const TextEditingDialog({super.key, this.defaultText});
  final String? defaultText;

  @override
  State<TextEditingDialog> createState() => _TextEditingDialogState();
}

class _TextEditingDialogState extends State<TextEditingDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _isFilePickerAlreadyActive = false; // 二重実行によるPlatformException(already_active, File picker is already active~ 対策

  // ファイル選択画面を表示してテキストを取り込む
  Future<void> _importFromFile() async {
    setState(() {
      _isFilePickerAlreadyActive = true; // 💡必ず戻すこと！returnにご用心
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('読み込み中…'), // ダイアログの裏に隠れてしまうがそれはそれでwabisabiがある
      duration: Duration(seconds: 90), // 既知: 読み込み中に背景をタップしてダイアログを閉じると表示されっぱなしになる。ファイル選択に手間取っていると勝手に消える。
    ));

    try {
      final result = await FilePicker.platform.pickFiles(); // 一部端末でDownloadのファイル選択すると例外。選択画面のままデバッグ停止→デバッグ開始でバグる。
      final path = result!.paths.first!; // ファイルを選択せず戻るとnullなので例外
      final contentText = File(path).readAsStringSync(); // テキストファイルでないとき例外
      _controller.text = contentText;
    } catch (e) {
      await Fluttertoast.showToast(msg: '🐸 読めません！\n$e');
      print('🤗いったいどのへんで例外になったのでしょう？: $e');
    }
    // ↕️時間経過あり
    if (mounted) {
      setState(() {
        _isFilePickerAlreadyActive = false;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
    // resultをnullチェック、文字列以外ならcatchして、そうだfalseに戻さないと…→結局どの関数もexceptionじゃないか！もうブチギレですよ！→巨大try-catch爆誕、そして迷宮へ…
  }

  // クリップボードから貼り付ける
  Future<void> _loadFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    _controller.text = clipboardData?.text ?? '';
  }

  @override
  void initState() {
    super.initState();

    _controller.text = widget.defaultText ?? ''; // TextFormFieldに初期値を代入する.
    _focusNode.addListener(
      () {
        // フォーカスが当たったときに文字列が選択された状態にする.
        if (_focusNode.hasFocus) {
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controller.text.length,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        content: TextFormField(
          autofocus: true, // ダイアログが開いたときに自動でフォーカスを当てる.
          focusNode: _focusNode,
          controller: _controller,
          maxLines: null, // Nullにすると複数行の入力ができる。《セリフを追加する》のためにnullにしたがJSONインポート時はごちゃつく.
          onFieldSubmitted: (_) {
            // エンターを押したときに実行される.
            Navigator.of(context).pop(_controller.text);
          },
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Tooltip(
                  message: 'クリップボードから貼り付ける',
                  child: IconButton(
                    onPressed: _loadFromClipboard,
                    icon: const Icon(Icons.paste_rounded),
                  ),
                ),
                Tooltip(
                  message: 'ファイルを読み込む',
                  child: IconButton(
                    onPressed: _isFilePickerAlreadyActive ? null : _importFromFile,
                    icon: const Icon(Icons.folder_open_outlined), // アイコンがopenしてない…？
                  ),
                ),
              ]),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(_controller.text);
                },
                child: const Text('完了', textAlign: TextAlign.end),
              ),
            ],
          ),
        ],
      );
}

// ↑の入力ダイアログを呼び出す関数.
Future<String?> showEditingDialog(BuildContext context, String defaultText) async {
  final whatYouInputted = await showDialog<String>(
    context: context,
    builder: (context) => TextEditingDialog(defaultText: defaultText),
  );

  return whatYouInputted;
}
