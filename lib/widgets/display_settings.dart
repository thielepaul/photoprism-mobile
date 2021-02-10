import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class DisplaySettings extends StatefulWidget {
  const DisplaySettings({Key key, this.context}) : super(key: key);
  final BuildContext context;

  @override
  _DisplaySettingsState createState() => _DisplaySettingsState(context);
}

class _DisplaySettingsState extends State<DisplaySettings> {
  _DisplaySettingsState(BuildContext context) {
    model = Provider.of<PhotoprismModel>(context);
    showPrivate = model.displaySettings.showPrivate;
  }

  PhotoprismModel model;
  bool showPrivate;

  @override
  Widget build(BuildContext context) {
    Future<void> saveAndPop() async {
      model.displaySettings.setShowPrivate(showPrivate);
      Navigator.of(context).pop();
    }

    return AlertDialog(
      title: const Text('display_settings').tr(),
      content: SingleChildScrollView(
          child: ListBody(
        children: <Widget>[
          SwitchListTile(
            title: const Text('include_private_content').tr(),
            onChanged: (bool value) {
              setState(() {
                showPrivate = value;
              });
            },
            value: showPrivate,
          ),
        ],
      )),
      actions: <Widget>[
        FlatButton(
          child: const Text('cancel').tr(),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: const Text('save').tr(),
          onPressed: () => saveAndPop(),
        )
      ],
    );
  }
}
