import 'package:easy_localization/easy_localization.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeDialog extends StatefulWidget {
  const ThemeDialog({Key? key, this.context}) : super(key: key);
  final BuildContext? context;

  @override
  _ThemeDialogState createState() => _ThemeDialogState(context!);
}

class _ThemeDialogState extends State<ThemeDialog> {
  _ThemeDialogState(BuildContext context) {
    model = Provider.of<PhotoprismModel>(context);
    selectedRadio = model.themeMode!.index;
  }

  late PhotoprismModel model;
  int? selectedRadio;

  @override
  Widget build(BuildContext context) {
    Future<void> saveAndPop() async {
      model.themeMode = ThemeMode.values[selectedRadio!];
      final SharedPreferences sp = await SharedPreferences.getInstance();
      sp.setString('theme_mode',
          EnumToString.convertToString(ThemeMode.values[selectedRadio!]));
      Navigator.of(context).pop();
    }

    return AlertDialog(
      title: const Text('theme').tr(),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children:
                List<Widget>.generate(ThemeMode.values.length, (int index) {
              return RadioListTile<int>(
                title:
                    Text(EnumToString.convertToString(ThemeMode.values[index]))
                        .tr(),
                value: index,
                groupValue: selectedRadio,
                onChanged: (int? value) {
                  setState(() => selectedRadio = value);
                },
              );
            }),
          );
        },
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('cancel').tr(),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('save').tr(),
          onPressed: () => saveAndPop(),
        )
      ],
    );
  }
}
