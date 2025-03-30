import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:voicevox_flutter/voicevox_flutter.dart';

// パッケージから assets/ にアクセスできないことが判明したのでここでファイルを操作することにした
// アプリ内でしかできないことだけ書く…予定

class VoicevoxFlutterController {
  late final VoicevoxFlutter voicevoxFlutter;

  // オリチャー: モデルが必要になってからメモリ上に展開する
  final List<String> _loadedModelNames = [];
  late final Map<String, dynamic> _styleIdModelNameMap;

  /// voicevox_flutterを起動する
  Future<void> initialize() async {
    voicevoxFlutter = VoicevoxFlutter();

    // アセットからアプリケーションディレクトリに`open_jtalk_dict`をコピーする
    final openJTalkDictDir = Directory('${(await getApplicationSupportDirectory()).path}/open_jtalk_dic_utf_8-1.11');
    if (!openJTalkDictDir.existsSync()) {
      openJTalkDictDir.createSync();
      final openJTalkDictAssetDir = Directory('assets/open_jtalk_dic_utf_8-1.11');

      final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> assets = assetManifest.listAssets();
      // open_jtalk_dic_utf_8-1.11ディレクトリ以下のファイルをコピーする。forEachではawaitできてない疑惑があったためfor-inの素直な記述に改めた
      final openJTalkAssets = assets.where((e) => e.contains(openJTalkDictAssetDir.path)).toList();
      for (final path in openJTalkAssets) {
        await _copyFile(fileName: p.basename(path), from: openJTalkDictAssetDir, to: openJTalkDictDir);
      }
    }
    await voicevoxFlutter.initialize(openJTalkDictDir: openJTalkDictDir);

    // オリチャーの準備もする
    final modelNameMapAsText = await rootBundle.loadString('assets/styleIdToModelName.json');
    _styleIdModelNameMap = jsonDecode(modelNameMapAsText);
  }

  /// テキストから AudioQuery を生成する
  Future<String> textToAudioQuery({required String text, required int styleId}) async {
    await _prepareModel(styleId: styleId);
    final output = await voicevoxFlutter.textToAudioQuery(text: text, styleId: styleId);
    return output;
  }

  /// AudioQuery から音声合成する
  Future<File> audioQueryToWav({required String audioQuery, required int styleId}) async {
    await _prepareModel(styleId: styleId);
    final wavFile = File('${(await getTemporaryDirectory()).path}/${audioQuery.hashCode}.wav');
    await voicevoxFlutter.audioQueryToWav(audioQuery: audioQuery, styleId: styleId, output: wavFile);
    return wavFile;
  }

  // 必要なVVMモデルを探してロードする関数。モデルが必要になる前に実行すること
  Future<void> _prepareModel({required int styleId}) async {
    final requiredModelName = _styleIdModelNameMap[styleId.toString()];
    if (requiredModelName == null) {
      throw Exception('このstyleId: $styleIdに対応するモデル.vvmがどれなのかわかりません😫 assets/styleIdToModelName.jsonを更新してください。');
    }

    if (_loadedModelNames.contains(requiredModelName)) {
      return;
    }

    debugPrint('${DateTime.now()}😸VVMモデル$requiredModelNameが必要になったので読み込みます');
    // TODO: これもファイルが存在するかどうかで分岐する

    // アセットからアプリケーションディレクトリに`model`をコピーする
    final modelAssetDir = Directory('assets/model');
    final modelDir = Directory('${(await getTemporaryDirectory()).path}/model');
    await modelDir.create();
    await _copyFile(fileName: requiredModelName, from: modelAssetDir, to: modelDir);

    await voicevoxFlutter.loadVoiceModel(modelFile: File('${modelDir.path}/$requiredModelName'));

    debugPrint('${DateTime.now()}😹VVMモデル${modelDir.path}/$requiredModelNameを読み込みました');
    _loadedModelNames.add(requiredModelName);
  }

  void dispose() {
    voicevoxFlutter.dispose();
  }
}

/// 指定されたファイル（assets/を想定）をコピーする
Future<void> _copyFile({required String fileName, required Directory from, required Directory to}) async {
  // とりあえずStringは曖昧かなと思って手を出してみたもののなんも変わってない気がする
  final data = await rootBundle.load('${from.path}/$fileName'); // 別isolateの中でrootBundleは動かんらしい
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  await File('${to.path}/$fileName').writeAsBytes(bytes);
}

/// AudioQueryに対応するWAVの保存先を案内する。キャッシュがなければnullを返す
Future<File?> navigateWavCache(Map<String, dynamic> query) async {
  final queryAsString = jsonEncode(query);
  final file = File('${(await getTemporaryDirectory()).path}/${queryAsString.hashCode}.wav');

  if (await file.exists()) {
    return file;
  } else {
    return null;
  }
}
