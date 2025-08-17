import 'package:flutter/material.dart';

import 'audio_query_type.dart';
import 'entrance_snackbar.dart';
import 'voice_params_edit_page.dart';
import 'voice_params_type.dart';

/// AudioQuery編集UIの外骨格。ModalBottomSheetの中に表示して使う
class AudioQueryEditor extends StatefulWidget {
  const AudioQueryEditor({
    super.key,
    required this.initialPageIndex,
    required this.initialAudioQuery,
    required this.onFeedbackWhenDispose,
  });

  final EditSheetPageEnum initialPageIndex;
  final AudioQuery initialAudioQuery;

  /// 編集UIが閉じられるとき、ダイイングメッセージのように最終的な編集結果を返す。受け取った者には、このAudioQueryを着実に反映させることが求められる。
  final void Function(AudioQuery) onFeedbackWhenDispose;

  @override
  State<AudioQueryEditor> createState() => _AudioQueryEditorState();
}

class _AudioQueryEditorState extends State<AudioQueryEditor> {
  late EditSheetPageEnum _currentPageIndex;

  late AudioQuery _audioQuery;

  void _updateVoiceParameters(VoiceParams newParameters) {
    _audioQuery.speedScale = newParameters.speedScale;
    _audioQuery.pitchScale = newParameters.pitchScale;
    _audioQuery.intonationScale = newParameters.intonationScale;
    _audioQuery.volumeScale = newParameters.volumeScale;
    _audioQuery.prePhonemeLength = newParameters.prePhonemeLength;
    _audioQuery.postPhonemeLength = newParameters.postPhonemeLength;
  }

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialPageIndex;
    _audioQuery = widget.initialAudioQuery;
  }

  @override
  void dispose() {
    super.dispose();
    widget.onFeedbackWhenDispose(_audioQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // enumに連動してページを切り替える
        switch (_currentPageIndex) {
          EditSheetPageEnum.accentEditPage => Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Column(
              children: [
                Text('😋', style: Theme.of(context).textTheme.headlineLarge),
                Text('この機能はありません', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),

          EditSheetPageEnum.intonationEditPage => Padding(
            padding: EdgeInsets.symmetric(vertical: 100),
            child: Column(
              children: [
                Text('😎', style: Theme.of(context).textTheme.headlineLarge),
                Text('この機能はありません', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),

          EditSheetPageEnum.lengthEditPage => Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Text('😙', style: Theme.of(context).textTheme.headlineLarge),
                Text('この機能はありません', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),

          EditSheetPageEnum.parameterEditPage => SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: VoiceParamsEditPage(
              initialParameters: VoiceParams(
                speedScale: _audioQuery.speedScale,
                pitchScale: _audioQuery.pitchScale,
                intonationScale: _audioQuery.intonationScale,
                volumeScale: _audioQuery.volumeScale,
                prePhonemeLength: _audioQuery.prePhonemeLength,
                postPhonemeLength: _audioQuery.postPhonemeLength,
              ),
              onParametersChanged: _updateVoiceParameters,
            ),
          ),

          EditSheetPageEnum.closePage => const SizedBox.shrink(),
        },

        NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              _currentPageIndex = EditSheetPageEnum.fromId(index);
            });
            if (EditSheetPageEnum.fromId(index) == EditSheetPageEnum.closePage) {
              Navigator.pop(context); // 編集UIを閉じる
            }
          },
          selectedIndex: _currentPageIndex.id,
          destinations: const <Widget>[
            NavigationDestination(selectedIcon: Icon(Icons.show_chart), icon: Icon(Icons.show_chart), label: 'アクセント'),
            NavigationDestination(icon: Icon(Icons.height), label: 'イントネーション'),
            NavigationDestination(icon: RotatedBox(quarterTurns: 1, child: Icon(Icons.height)), label: '長さ'),
            NavigationDestination(icon: Icon(Icons.tune), label: '話速/抑揚…'),
            NavigationDestination(icon: Icon(Icons.close), label: '閉じる'),
          ],
        ),
      ],
    );
  }
}
