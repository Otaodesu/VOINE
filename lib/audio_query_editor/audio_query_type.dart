import 'dart:convert';

// AudioQuery型を作り、myAudioQuery.accentPhrases.lengthのように扱えるようにするClass群。Geminiに生成してもらった。
// Geminiは各フィールドをfinalにして生成してきたが、編集可能なUIを作りたいので外した

// Moraクラス (モーラ情報を表す)
class Mora {
  String text;
  String? consonant; // nullの場合がある
  double? consonantLength; // nullの場合がある
  String vowel;
  double vowelLength;
  double pitch;

  Mora({
    required this.text,
    this.consonant,
    this.consonantLength,
    required this.vowel,
    required this.vowelLength,
    required this.pitch,
  });

  factory Mora.fromJson(Map<String, dynamic> json) {
    return Mora(
      text: json['text'] as String,
      consonant: json['consonant'] as String?, // null許容
      consonantLength: (json['consonant_length'] as num?)?.toDouble(), // null許容 & double変換
      vowel: json['vowel'] as String,
      vowelLength: (json['vowel_length'] as num).toDouble(), // double変換
      pitch: (json['pitch'] as num).toDouble(), // double変換
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'consonant': consonant,
      'consonant_length': consonantLength,
      'vowel': vowel,
      'vowel_length': vowelLength,
      'pitch': pitch,
    };
  }

  @override
  String toString() {
    return 'Mora(text: $text, consonant: $consonant, consonantLength: $consonantLength, vowel: $vowel, vowelLength: $vowelLength, pitch: $pitch)';
  }
}

// AccentPhraseクラス (アクセント句情報を表す)
class AccentPhrase {
  final List<Mora> moras;
  final int accent;
  final Mora? pauseMora; // nullの場合がある
  final bool isInterrogative;

  AccentPhrase({required this.moras, required this.accent, this.pauseMora, required this.isInterrogative});

  factory AccentPhrase.fromJson(Map<String, dynamic> json) {
    // morasリストをパース
    var morasList = json['moras'] as List;
    List<Mora> moras = morasList.map((m) => Mora.fromJson(m)).toList();

    // pause_moraをパース (nullチェック)
    Mora? pauseMora;
    if (json['pause_mora'] != null) {
      pauseMora = Mora.fromJson(json['pause_mora']);
    }

    return AccentPhrase(
      moras: moras,
      accent: json['accent'] as int,
      pauseMora: pauseMora, // null許容
      isInterrogative: json['is_interrogative'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moras': moras.map((m) => m.toJson()).toList(),
      'accent': accent,
      'pause_mora': pauseMora?.toJson(), // null安全な呼び出し
      'is_interrogative': isInterrogative,
    };
  }

  @override
  String toString() {
    return 'AccentPhrase(moras: ${moras.length}, accent: $accent, pauseMora: ${pauseMora != null}, isInterrogative: $isInterrogative)';
  }
}

// AudioQueryクラス (全体の構造を表す)
class AudioQuery {
  List<AccentPhrase> accentPhrases;
  double speedScale;
  double pitchScale;
  double intonationScale;
  double volumeScale;
  double prePhonemeLength;
  double postPhonemeLength;
  int outputSamplingRate;
  bool outputStereo;
  String kana;

  AudioQuery({
    required this.accentPhrases,
    required this.speedScale,
    required this.pitchScale,
    required this.intonationScale,
    required this.volumeScale,
    required this.prePhonemeLength,
    required this.postPhonemeLength,
    required this.outputSamplingRate,
    required this.outputStereo,
    required this.kana,
  });

  factory AudioQuery.fromJson(Map<String, dynamic> json) {
    // accent_phrasesリストをパース
    var accentPhrasesList = json['accent_phrases'] as List;
    List<AccentPhrase> accentPhrases = accentPhrasesList.map((ap) => AccentPhrase.fromJson(ap)).toList();

    return AudioQuery(
      accentPhrases: accentPhrases,
      speedScale: (json['speedScale'] as num).toDouble(),
      pitchScale: (json['pitchScale'] as num).toDouble(),
      intonationScale: (json['intonationScale'] as num).toDouble(),
      volumeScale: (json['volumeScale'] as num).toDouble(),
      prePhonemeLength: (json['prePhonemeLength'] as num).toDouble(),
      postPhonemeLength: (json['postPhonemeLength'] as num).toDouble(),
      outputSamplingRate: json['outputSamplingRate'] as int,
      outputStereo: json['outputStereo'] as bool,
      kana: json['kana'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accent_phrases': accentPhrases.map((ap) => ap.toJson()).toList(),
      'speedScale': speedScale,
      'pitchScale': pitchScale,
      'intonationScale': intonationScale,
      'volumeScale': volumeScale,
      'prePhonemeLength': prePhonemeLength,
      'postPhonemeLength': postPhonemeLength,
      'outputSamplingRate': outputSamplingRate,
      'outputStereo': outputStereo,
      'kana': kana,
    };
  }

  @override
  String toString() {
    return 'AudioQuery(accentPhrases: ${accentPhrases.length}, speedScale: $speedScale, ..., kana: $kana)';
  }
}

// --- 使用例 ---
void checkAudioQueryType() {
  const jsonString = '''
    {
        "accent_phrases": [
            {
                "moras": [
                    {
                        "text": "キョ",
                        "consonant": "ky",
                        "consonant_length": 0.13512386,
                        "vowel": "o",
                        "vowel_length": 0.11260741,
                        "pitch": 5.979024
                    },
                    {
                        "text": "オ",
                        "consonant": null,
                        "consonant_length": null,
                        "vowel": "o",
                        "vowel_length": 0.10102179,
                        "pitch": 6.048895
                    },
                    {
                        "text": "ワ",
                        "consonant": "w",
                        "consonant_length": 0.05987209,
                        "vowel": "a",
                        "vowel_length": 0.09553378,
                        "pitch": 5.775944
                    }
                ],
                "accent": 1,
                "pause_mora": null,
                "is_interrogative": false
            },
            {
                "moras": [
                    {
                        "text": "ハ",
                        "consonant": "h",
                        "consonant_length": 0.09416669,
                        "vowel": "a",
                        "vowel_length": 0.08645181,
                        "pitch": 5.6065865
                    },
                    {
                        "text": "レ",
                        "consonant": "r",
                        "consonant_length": 0.035750274,
                        "vowel": "e",
                        "vowel_length": 0.089439355,
                        "pitch": 5.8345914
                    },
                    {
                        "text": "デ",
                        "consonant": "d",
                        "consonant_length": 0.05084079,
                        "vowel": "e",
                        "vowel_length": 0.14279577,
                        "pitch": 5.970788
                    },
                    {
                        "text": "ス",
                        "consonant": "s",
                        "consonant_length": 0.074652575,
                        "vowel": "U",
                        "vowel_length": 0.113135435,
                        "pitch": 0.0
                    }
                ],
                "accent": 2,
                "pause_mora": {
                    "text": "、",
                    "consonant": null,
                    "consonant_length": null,
                    "vowel": "pau",
                    "vowel_length": 0.38060328,
                    "pitch": 0.0
                },
                "is_interrogative": false
            },
            {
                "moras": [
                    {
                        "text": "ア",
                        "consonant": null,
                        "consonant_length": null,
                        "vowel": "a",
                        "vowel_length": 0.178814,
                        "pitch": 5.541234
                    },
                    {
                        "text": "シ",
                        "consonant": "sh",
                        "consonant_length": 0.044174504,
                        "vowel": "I",
                        "vowel_length": 0.075131334,
                        "pitch": 0.0
                    },
                    {
                        "text": "タ",
                        "consonant": "t",
                        "consonant_length": 0.07260111,
                        "vowel": "a",
                        "vowel_length": 0.11170767,
                        "pitch": 6.088499
                    },
                    {
                        "text": "モ",
                        "consonant": "m",
                        "consonant_length": 0.05979722,
                        "vowel": "o",
                        "vowel_length": 0.17552374,
                        "pitch": 5.9886584
                    }
                ],
                "accent": 3,
                "pause_mora": {
                    "text": "、",
                    "consonant": null,
                    "consonant_length": null,
                    "vowel": "pau",
                    "vowel_length": 0.29025805,
                    "pitch": 0.0
                },
                "is_interrogative": false
            },
            {
                "moras": [
                    {
                        "text": "ハ",
                        "consonant": "h",
                        "consonant_length": 0.102033935,
                        "vowel": "a",
                        "vowel_length": 0.0898853,
                        "pitch": 5.5710053
                    },
                    {
                        "text": "レ",
                        "consonant": "r",
                        "consonant_length": 0.03653113,
                        "vowel": "e",
                        "vowel_length": 0.10744362,
                        "pitch": 5.848797
                    },
                    {
                        "text": "ル",
                        "consonant": "r",
                        "consonant_length": 0.042263962,
                        "vowel": "u",
                        "vowel_length": 0.10107373,
                        "pitch": 6.180284
                    },
                    {
                        "text": "カ",
                        "consonant": "k",
                        "consonant_length": 0.0653508,
                        "vowel": "a",
                        "vowel_length": 0.13739784,
                        "pitch": 6.009556
                    },
                    {
                        "text": "ナ",
                        "consonant": "n",
                        "consonant_length": 0.046945296,
                        "vowel": "a",
                        "vowel_length": 0.23183429,
                        "pitch": 5.8110433
                    }
                ],
                "accent": 2,
                "pause_mora": null,
                "is_interrogative": true
            }
        ],
        "speedScale": 1.0,
        "pitchScale": 0.0,
        "intonationScale": 1.0,
        "volumeScale": 1.0,
        "prePhonemeLength": 0.1,
        "postPhonemeLength": 0.1,
        "outputSamplingRate": 24000,
        "outputStereo": false,
        "kana": "キョ'オワ/ハレ'デ_ス、ア_シタ'モ、ハレ'ルカナ？"
    }
  ''';

  // JSON文字列をデコードしてMapにする
  final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

  // MapからAudioQueryオブジェクトを生成
  var audioQuery = AudioQuery.fromJson(jsonMap);

  // データへのアクセス例
  print('カナ: ${audioQuery.kana}');
  print('アクセント句の数: ${audioQuery.accentPhrases.length}');
  print('最初のアクセント句のモーラ数: ${audioQuery.accentPhrases[0].moras.length}');
  print('最初のモーラのテキスト: ${audioQuery.accentPhrases[0].moras[0].text}');
  print('2番目のアクセント句のポーズモーラ: ${audioQuery.accentPhrases[1].pauseMora}'); // nullが出力されるはず

  // AudioQueryオブジェクトをJSON文字列にエンコード
  final encodedJson = jsonEncode(audioQuery.toJson());
  print('\nエンコードされたJSON:\n$encodedJson');
}
