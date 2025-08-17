import 'package:flutter/material.dart';

/// Snackbarの中に表示してAudioQuery編集画面に誘導するためのウィジェット。名前決まらん。バナー広告のようにひょこひょこ表示するからEditorAdvertisingBar？
class EditorEntranceBar extends StatelessWidget {
  const EditorEntranceBar({super.key, required this.onSnackBarButtonPressed});

  final void Function(EditSheetPageEnum) onSnackBarButtonPressed;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      onDestinationSelected: (int index) {
        if (EditSheetPageEnum.fromId(index) != EditSheetPageEnum.closePage) {
          onSnackBarButtonPressed(EditSheetPageEnum.fromId(index));
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      selectedIndex: EditSheetPageEnum.closePage.id,
      destinations: const <Widget>[
        NavigationDestination(selectedIcon: Icon(Icons.show_chart), icon: Icon(Icons.show_chart), label: 'アクセント'),
        NavigationDestination(icon: Icon(Icons.height), label: 'イントネーション'),
        NavigationDestination(icon: RotatedBox(quarterTurns: 1, child: Icon(Icons.height)), label: '長さ'),
        NavigationDestination(icon: Icon(Icons.tune), label: '話速/抑揚…'),
        NavigationDestination(icon: Icon(Icons.close), label: '閉じる'),
      ],
    );
  }
}

/// どのページが選択されたかenumで受け渡すとかっこよさそうなので作った。
enum EditSheetPageEnum {
  accentEditPage(0),
  intonationEditPage(1),
  lengthEditPage(2),
  parameterEditPage(3),
  closePage(4);

  const EditSheetPageEnum(this.id);

  final int id;

  static EditSheetPageEnum fromId(int id) {
    return EditSheetPageEnum.values.firstWhere((e) => e.id == id, orElse: () => throw ArgumentError('Invalid id: $id'));
  }
}
