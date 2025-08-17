import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'voice_params_type.dart';

/// 話速、音高、抑揚…を編集するスライダーを並べたページ。本家VOICEVOXの右に表示されるあの…アレ。
class VoiceParamsEditPage extends StatefulWidget {
  const VoiceParamsEditPage({super.key, required this.initialParameters, required this.onParametersChanged});

  /// BottomSheet → このウィジェット のデータ送信は1回きり（ウィジェット構築時だけ）
  final VoiceParams initialParameters;

  /// BottomSheet ← このウィジェット のデータ送信はスライダーを操作するたびに行われるつもりでいる！
  final void Function(VoiceParams) onParametersChanged; // スライダー操作のたびにフィードバックしていれば、disposeするときはフィードバックしなくてよくなる

  @override
  State<StatefulWidget> createState() {
    return _VoiceParamsEditPageState();
  }
}

class _VoiceParamsEditPageState extends State<VoiceParamsEditPage> {
  double _speedScale = 1;
  double _pitchScale = 0;
  double _intonationScale = 1;
  double _volumeScale = 1;
  double _prePhonemeLength = 0.1;
  double _postPhonemeLength = 0.1;

  void _letsFeedbackParameters() {
    print('😝スライダーの値をフィードバックします');
    widget.onParametersChanged(
      VoiceParams(
        speedScale: _speedScale,
        pitchScale: _pitchScale,
        intonationScale: _intonationScale,
        volumeScale: _volumeScale,
        prePhonemeLength: _prePhonemeLength,
        postPhonemeLength: _postPhonemeLength,
      ),
    );
  }

  void _initialize() async {
    // Sliderにmin-maxの範囲外を入力するとぶっ壊れるのでバリデーションする。ウィジェットを構築するタイミングだけでいい。
    if (widget.initialParameters.speedScale >= 0.5 && widget.initialParameters.speedScale <= 2) {
      setState(() {
        _speedScale = widget.initialParameters.speedScale;
      });
    }
    if (widget.initialParameters.pitchScale >= -0.15 && widget.initialParameters.pitchScale <= 0.15) {
      setState(() {
        _pitchScale = widget.initialParameters.pitchScale;
      });
    }
    if (widget.initialParameters.intonationScale >= 0 && widget.initialParameters.intonationScale <= 2) {
      setState(() {
        _intonationScale = widget.initialParameters.intonationScale;
      });
    }
    if (widget.initialParameters.volumeScale >= 0 && widget.initialParameters.volumeScale <= 2) {
      setState(() {
        _volumeScale = widget.initialParameters.volumeScale;
      });
    }
    if (widget.initialParameters.prePhonemeLength >= 0 && widget.initialParameters.prePhonemeLength <= 1.5) {
      setState(() {
        _prePhonemeLength = widget.initialParameters.prePhonemeLength;
      });
    }
    if (widget.initialParameters.postPhonemeLength >= 0 && widget.initialParameters.postPhonemeLength <= 1.5) {
      setState(() {
        _postPhonemeLength = widget.initialParameters.postPhonemeLength;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              child: Column(
                children: [
                  // スライダーたち。まずは話速から。
                  ListTile(
                    title: Row(
                      children: [
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.speed),
                              onPressed: () {
                                setState(() {
                                  _speedScale = 1; // アイコンがタップされたらデフォルトのパラメータにもどす
                                });
                                _letsFeedbackParameters(); // 値をフィードバックする（ことでイントロ音声を鳴らしてもらう）
                              },
                            ),
                            Text('話速', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Expanded(
                          child: Slider(
                            value: _speedScale,
                            min: 0.5,
                            max: 2,
                            onChanged:
                                (value) => setState(() {
                                  _speedScale = value;
                                }),
                            onChangeEnd: (_) => _letsFeedbackParameters(), // 指を離したタイミングで値をフィードバックする
                          ),
                        ),
                        Text(_speedScale.toStringAsFixed(2)),
                      ],
                    ),
                  ),

                  ListTile(
                    title: Row(
                      children: [
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.music_note),
                              onPressed: () {
                                setState(() {
                                  _pitchScale = 0;
                                });
                                _letsFeedbackParameters();
                              },
                            ),
                            Text('音高', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Expanded(
                          child: Slider(
                            value: _pitchScale,
                            min: -0.15,
                            max: 0.15,
                            onChanged:
                                (value) => setState(() {
                                  _pitchScale = value;
                                }),
                            onChangeEnd: (_) => _letsFeedbackParameters(),
                          ),
                        ),
                        Text(_pitchScale.toStringAsFixed(2)),
                      ],
                    ),
                  ),

                  ListTile(
                    title: Row(
                      children: [
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.trending_up),
                              onPressed: () {
                                setState(() {
                                  _intonationScale = 1;
                                });
                                _letsFeedbackParameters();
                              },
                            ),
                            Text('抑揚', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Expanded(
                          child: Slider(
                            value: _intonationScale,
                            min: 0,
                            max: 2,
                            onChanged:
                                (value) => setState(() {
                                  _intonationScale = value;
                                }),
                            onChangeEnd: (_) => _letsFeedbackParameters(),
                          ),
                        ),
                        Text(_intonationScale.toStringAsFixed(2)),
                      ],
                    ),
                  ),

                  ListTile(
                    title: Row(
                      children: [
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.volume_up),
                              onPressed: () {
                                setState(() {
                                  _volumeScale = 1;
                                });
                                _letsFeedbackParameters();
                              },
                            ),
                            Text('音量', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Expanded(
                          child: Slider(
                            value: _volumeScale,
                            min: 0,
                            max: 2,
                            onChanged:
                                (value) => setState(() {
                                  _volumeScale = value;
                                }),
                            onChangeEnd: (_) => _letsFeedbackParameters(),
                          ),
                        ),
                        Text(_volumeScale.toStringAsFixed(2)),
                      ],
                    ),
                  ),

                  ListTile(
                    title: Row(
                      children: [
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.logout),
                              onPressed: () {
                                setState(() {
                                  _prePhonemeLength = 0.1;
                                });
                                _letsFeedbackParameters();
                              },
                            ),
                            Text('開始無音', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Expanded(
                          child: Slider(
                            value: _prePhonemeLength,
                            min: 0,
                            max: 1.5,
                            onChanged:
                                (value) => setState(() {
                                  _prePhonemeLength = value;
                                }),
                            onChangeEnd: (_) => _letsFeedbackParameters(),
                          ),
                        ),
                        Text(_prePhonemeLength.toStringAsFixed(2)),
                      ],
                    ),
                  ),

                  ListTile(
                    title: Row(
                      children: [
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.login),
                              onPressed: () {
                                setState(() {
                                  _postPhonemeLength = 0.1;
                                });
                                _letsFeedbackParameters();
                              },
                            ),
                            Text('終了無音', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Expanded(
                          child: Slider(
                            value: _postPhonemeLength,
                            min: 0,
                            max: 1.5,
                            onChanged:
                                (value) => setState(() {
                                  _postPhonemeLength = value;
                                }),
                            onChangeEnd: (_) => _letsFeedbackParameters(),
                          ),
                        ),
                        Text(_postPhonemeLength.toStringAsFixed(2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Card(
              child: Column(
                children: [
                  SimpleDialogOption(
                    onPressed: () => Fluttertoast.showToast(msg: '🥰この機能はありません'),
                    child: ListTile(leading: Icon(Icons.bookmark_add), title: Text('プリセットに保存する')),
                  ),
                  SimpleDialogOption(
                    onPressed: () => Fluttertoast.showToast(msg: '🤩この機能はありません'),
                    child: ListTile(leading: Icon(Icons.folder), title: Text('プリセットを読み込む')),
                  ),
                  SimpleDialogOption(
                    onPressed: () => Fluttertoast.showToast(msg: '😴この機能はありません'),
                    child: ListTile(leading: Icon(Icons.library_add_check), title: Text('複数のセリフに適用する')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
