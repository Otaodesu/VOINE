# VOINE
- VOICEVOXをLINE風のチャットUIで遊ぶアプリです。
- 完全非公式です。
- GitHubなるものの練習を兼ねています。
- noteにて、このアプリの[スクリーンショットを見られます](https://note.com/iseudondes/n/nea9229a4b897)。

## 使用している技術は？
- メイン言語: Dart/[Flutter](https://flutter.dev/)
- チャットUI: [flutter_chat_ui 🇺🇦](https://pub.dev/packages/flutter_chat_ui)
- 音声合成: [voicevox_flutter](https://github.com/char5742/voicevox_flutter)

## ライセンスは？
- ソースコード本体は、本家VOICEVOXにならってLGPL-3.0とします。好きに改造しやがれ！
- 合成した音声の利用規約は、[こちら](https://voicevox.hiroshiba.jp/)を確認してください。
- キャラクター名などの権利は、各団体等に帰属します。

## ビルドまでの手順
簡単で す！

### 1. 準備するもの
  - [ ] Flutterの開発環境
    -  サンプルアプリ（カウンターのやつ）がビルドできるようにしてください。

### 2. ダウンロードする
  - [ ] VOINE（このリポジトリ）

  - [ ] voicevox_flutterの改造版  
    -  https://github.com/Otaodesu/voicevox_flutter

  - [ ] OpenJTalkの辞書ファイル  
    -  https://open-jtalk.sourceforge.net/
    -  "Binary Package (UTF-8)" を選択します  

  - [ ] VOICEVOX コア音声モデル  
    -  https://github.com/VOICEVOX/voicevox_vvm/tree/main/vvms  

### 3. ファイルを配置する
  - [ ] `open_jtalk_dic_utf_8-1.11` の中身すべてを `voine/assets/open_jtalk_dic_utf_8-1.11` にコピーします

  - [ ] `voicevox_vvm-main/vvms` の中身すべてを `voine/assets/model` にコピーします

### 4. voicevox_flutterを紐づける
  - [ ] `voine/pubspec.yaml`を開き、以下の部分を `voicevox_flutter-main` のフォルダパスに書き換えてください

```yaml
  voicevox_flutter:  
    path: ../voicevox_flutter-for_core_0.16.0-preview.0  
    # 😆ビルドする前に、voicevox_flutterライブラリのフォルダパスに書き換えてください
```

### 5. 依存関係を解決する
  - [ ] `voine/` に移動して、`flutter pub get` を行います

これでapkファイルがビルドできるようになるはずです！おつかれさまでした！
