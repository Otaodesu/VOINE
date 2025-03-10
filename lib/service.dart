import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:voicevox_flutter/voicevox_flutter.dart';

// このファイルは https://github.com/char5742/voicevox_flutter/blob/dependency-voicevox_core-v0.15.0-preview.13/example/lib/service.dart (271c918) を改変したものです。
// ライセンス:  https://github.com/char5742/voicevox_flutter/blob/dependency-voicevox_core-v0.15.0-preview.13/LICENSE
// 謝辞と謝罪: char5742さん、素晴らしいライブラリをありがとうございます！そして初心者感丸出しな改造をお詫びします…！

class NativeVoiceService {
  late final Isolate isolate;
  late final SendPort sendPort;

  // 早速オリチャー発動！必要になったタイミングでコアにモデルを読み込ませるようにした
  final List<String> _loadedModelNames = []; // 読み込み済みのモデル名.vvmを格納する
  late final Map<String, dynamic>
  _styleIdToModelNameMap; // {"styleId": "modelName.vvm"}形式のマップ。lateの使い方わからん🙃

  bool isReady = false; // 音声合成が受付可能なときtrueにする

  Future<void> initialize() async {
    final modelNameMapAsText = await rootBundle.loadString(
      'assets/styleIdToModelName.json',
    );
    _styleIdToModelNameMap = jsonDecode(modelNameMapAsText);

    final receivePort = ReceivePort();
    final rootToken = RootIsolateToken.instance!;
    isolate = await Isolate.spawn<(SendPort, RootIsolateToken)>((
      message,
    ) async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(message.$2);

      final receivePort = ReceivePort();
      message.$1.send(receivePort.sendPort);

      receivePort.listen((message) async {
        message = message as Map<String, dynamic>;

        switch (message['method']) {
          case 'initialize':
            await _initialize(message['openJdkDictPath'] as String);
            (message['sendPort'] as SendPort).send(null);
          case 'audioQuery':
            (message['sendPort'] as SendPort).send(
              _audioQuery(message['text'] as String, message['styleId'] as int),
            );
          case 'synthesis':
            (message['sendPort'] as SendPort).send(
              await _synthesis(
                message['query'] as String,
                message['styleId'] as int,
              ),
            );
          case 'tts':
            (message['sendPort'] as SendPort).send(
              await _tts(message['query'] as String, message['styleId'] as int),
            );
          case 'loadVoiceModel':
            await _loadVoiceModel(message['modelPath'] as String);
            (message['sendPort'] as SendPort).send(null);
        }
      });
    }, (receivePort.sendPort, rootToken));
    sendPort = await receivePort.first as SendPort;

    final r = ReceivePort();
    sendPort.send({
      'method': 'initialize',
      'openJdkDictPath': await _setOpenJdkDict(),
      'sendPort': r.sendPort,
    });
    await r.first;

    isReady = true;
  }

  /// オリチャーの根幹部分。モデルが必要な処理の前に実行すること。パブリックにすると若干高速化の道が開けるかも？
  Future<void> _prepareModel(int styleId) async {
    final requiredModelName = _styleIdToModelNameMap[styleId.toString()];

    if (requiredModelName == null) {
      throw Exception(
        'このstyleId: $styleIdに対応するモデル.vvmがどれなのかわかりません😫 assets/styleIdToModelName.jsonを更新してください。',
      );
    }

    if (_loadedModelNames.contains(requiredModelName)) {
      return;
    }

    print('${DateTime.now()}😸VVMモデル$requiredModelNameが必要になったので読み込みます');

    /// アセットからアプリケーションディレクトリに`model`をコピーする
    const modelAssetDir = 'assets/model';
    final modelDir = Directory(
      '${(await getApplicationSupportDirectory()).path}/model',
    );
    modelDir.createSync();
    await _copyFile(requiredModelName, modelAssetDir, modelDir.path);

    // isolate内で実行する
    final receivePort = ReceivePort();
    sendPort.send({
      'method': 'loadVoiceModel',
      'modelPath': '${modelDir.path}/$requiredModelName',
      'sendPort': receivePort.sendPort,
    });
    await receivePort.first;

    print(
      '${DateTime.now()}😹VVMモデル${modelDir.path}/$requiredModelNameを読み込みました',
    );
    _loadedModelNames.add(requiredModelName);
  }

  /// AudioQuery を生成する
  Future<String> audioQuery(String text, int styleId) async {
    await _prepareModel(styleId); // オリチャー

    final receivePort = ReceivePort();
    sendPort.send({
      'method': 'audioQuery',
      'text': text,
      'styleId': styleId,
      'sendPort': receivePort.sendPort,
    });
    return (await receivePort.first) as String;
  }

  /// AudioQueryから合成を実行する
  Future<String> synthesis(String query, int styleId) async {
    await _prepareModel(styleId); // オリチャー

    final receivePort = ReceivePort();
    sendPort.send({
      'method': 'synthesis',
      'query': query,
      'styleId': styleId,
      'sendPort': receivePort.sendPort,
    });
    return (await receivePort.first) as String;
  }

  /// テキスト音声合成を実行する
  Future<String> tts(String query, int styleId) {
    // await prepareModel(styleId); // オリチャー…と思ったらこれだけasyncじゃない。使ってないのでそのままにした

    final receivePort = ReceivePort();
    sendPort.send({
      'method': 'tts',
      'query': query,
      'styleId': styleId,
      'sendPort': receivePort.sendPort,
    });
    return receivePort.first as Future<String>;
  }

  void dispose() {
    isolate.kill();
  }
} // isolate、完全に理解した。

Future<void> _initialize(String openJdkDictPath) async {
  await VoicevoxFlutter.instance.initialize(
    openJdkDictPath: openJdkDictPath,
    cpuNumThreads: 4,
  );
}

/// コアにVVMモデルを読み込ませる（RAMに展開する？）
Future<void> _loadVoiceModel(String modelPath) async {
  VoicevoxFlutter.instance.loadVoiceModel(modelPath);
}

String _audioQuery(String text, int styleId) {
  return VoicevoxFlutter.instance.audioQuery(text, styleId: styleId);
}

Future<String> _synthesis(String query, int styleId) async {
  final wavFile = File(
    '${(await getTemporaryDirectory()).path}/${query.hashCode}.wav',
  );
  final watch = Stopwatch()..start();
  VoicevoxFlutter.instance.synthesis(
    query,
    styleId: styleId,
    outputPath: wavFile.path,
  );
  watch.stop();
  // 合成にかかった時間を表示する
  debugPrint('⭐️${watch.elapsedMilliseconds}msで合成して${wavFile.path}に保存しました');
  return wavFile.path;
}

/// テキスト音声合成を実行する
Future<String> _tts(String query, int styleId) async {
  final wavFile = File(
    '${(await getTemporaryDirectory()).path}/${query.hashCode}.wav',
  );
  final watch = Stopwatch()..start();
  VoicevoxFlutter.instance.tts(
    query,
    styleId: styleId,
    outputPath: wavFile.path,
  );
  watch.stop();
  // 合成にかかった時間を表示する
  debugPrint('⭐️${watch.elapsedMilliseconds}msで合成して${wavFile.path}に保存しました');
  return wavFile.path;
}

//

/// アセットからアプリケーションディレクトリにファイルをコピーする
Future<void> _copyFile(
  String filename,
  String assetsDir,
  String targetDirPath,
) async {
  final data = await rootBundle.load('$assetsDir/$filename');
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  File('$targetDirPath/$filename').writeAsBytesSync(bytes);
}

/// アセットからアプリケーションディレクトリに`open_jtalk_dict`をコピーする
Future<String> _setOpenJdkDict() async {
  final openJdkDictDir = Directory(
    '${(await getApplicationSupportDirectory()).path}/open_jtalk_dic_utf_8-1.11',
  );

  if (!openJdkDictDir.existsSync()) {
    openJdkDictDir.createSync();
    const openJdkDicAssetDir = 'assets/open_jtalk_dic_utf_8-1.11';

    final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(
      rootBundle,
    );
    final List<String> assets = assetManifest.listAssets();
    // open_jtalk_dic_utf_8-1.11ディレクトリ以下のファイルをコピーする
    assets.where((e) => e.contains(openJdkDicAssetDir)).map(p.basename).forEach(
      (name) async {
        await _copyFile(name, openJdkDicAssetDir, openJdkDictDir.path);
      },
    );

    await Future.delayed(const Duration(seconds: 1)); // 初回起動時に例外が出るため。高速化の賜物？😌
  }

  // 🤣ここでassets\libvoicevox_onnxruntime.soも読み込んでしまう！！
  final onnxruntimeSoGoToDir = await getApplicationSupportDirectory();
  await _copyFile(
    'libvoicevox_onnxruntime.so',
    'assets',
    onnxruntimeSoGoToDir.path,
  );
  return openJdkDictDir.path;
}

//

/// AudioQueryに対応するWAVの保存先を案内する。キャッシュがなければnullを返す
Future<File?> navigateWavCache(Map<String, dynamic> query) async {
  final queryAsString = jsonEncode(query);
  final file = File(
    '${(await getTemporaryDirectory()).path}/${queryAsString.hashCode}.wav',
  );

  if (await file.exists()) {
    return file;
  } else {
    return null;
  }
}
