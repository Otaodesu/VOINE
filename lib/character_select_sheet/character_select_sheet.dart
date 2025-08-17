import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import 'favorability_gauge.dart';

/// 話者を選択するリストのウィジェット。拡張性を高めるためにmainから分離した
/// キャッシュしないようにしたけど意外と高速に表示できるっぽい
class CharacterSelectSheet extends StatefulWidget {
  const CharacterSelectSheet({
    super.key,
    required this.onAttachPhotoPressed,
    required this.onAttachFilePressed,
    required this.onCharacterPressed,
  });

  final VoidCallback onAttachPhotoPressed;
  final VoidCallback onAttachFilePressed;
  final void Function(types.User) onCharacterPressed;

  @override
  State<CharacterSelectSheet> createState() => _CharacterSelectSheetState();
}

class _CharacterSelectSheetState extends State<CharacterSelectSheet> {
  List<types.User> _charactersDictionary = [];
  Map<int, int> _speakerIdUseCountMap = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final listInList = await loadCharactersDictionary();

    final output = <types.User>[];
    for (final list in listInList) {
      for (final each in list) {
        output.add(each);
      }
    }
    setState(() {
      _charactersDictionary = output;
    });
    _speakerIdUseCountMap = await loadSpeakerIdUseCountMap(); // 実験中: setStateが必要かも
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      radius: const Radius.circular(10),
      child: ListView(
        children: <TextButton>[
          ..._charactersDictionary.map(
            (user) => TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onCharacterPressed(user);
                incrementSpeakerUseCount(
                  speakerId: user.updatedAt ?? -1, // 禍根: ID-1の使用履歴が増えるかも.
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${user.firstName}（${user.lastName}）'), // ずんだもん（ノーマル）
                  SpeakerFavorabilityGauge(speakerUseCount: _speakerIdUseCountMap[user.updatedAt] ?? 0),
                ],
              ),
            ),
          ),

          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onAttachPhotoPressed();
            },
            child: const Align(alignment: AlignmentDirectional.centerStart, child: Text('Photo')),
          ),

          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onAttachFilePressed();
            },
            child: const Align(alignment: AlignmentDirectional.centerStart, child: Text('File')),
          ),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Align(alignment: AlignmentDirectional.centerStart, child: Text('Cancel')),
          ),
        ],
      ),
    );
  }
}

/// キャラクター辞書を読み込む関数.
Future<List<List<types.User>>> loadCharactersDictionary() async {
  final honkeAsText = await rootBundle.loadString('assets/charactersDictionary.json');
  // ここで例外なら『［Flutter］Assets （テキスト、画像）の利用方法』。700msくらいかかってる.
  final honkeAsDynamic = json.decode(honkeAsText);

  // 本家のjsonを二重リストに変換していく。mainの_userと同じフォーマットにすること😹.
  final charactersDictionary = <List<types.User>>[];
  for (var i = 0; i < honkeAsDynamic.length; i++) {
    final styles = <types.User>[];
    for (var j = 0; j < honkeAsDynamic[i]['styles'].length; j++) {
      final styleAsUser = types.User(
        id: honkeAsDynamic[i]['speaker_uuid'],
        firstName: honkeAsDynamic[i]['name'],
        lastName: honkeAsDynamic[i]['styles'][j]['name'],
        updatedAt: honkeAsDynamic[i]['styles'][j]['id'], // 禍根: ここにstyleId!?!?
      );
      styles.add(styleAsUser);
    }
    charactersDictionary.add(styles);
  }
  return charactersDictionary;
}
