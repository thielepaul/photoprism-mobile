import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/settings_page.dart';
import 'package:provider/provider.dart';

class HttpAuthDialog extends StatefulWidget {
  const HttpAuthDialog({Key key, this.context}) : super(key: key);
  final BuildContext context;

  @override
  _HttpAuthDialogState createState() => _HttpAuthDialogState(context);
}

class _HttpAuthDialogState extends State<HttpAuthDialog> {
  _HttpAuthDialogState(BuildContext context) {
    model = Provider.of<PhotoprismModel>(context);
    _httpBasicUserController = TextEditingController();
    _httpBasicPasswordController = TextEditingController();
    enabled = model.photoprismHttpBasicAuth.enabled;
  }

  PhotoprismModel model;
  TextEditingController _httpBasicUserController;
  TextEditingController _httpBasicPasswordController;
  bool enabled;

  @override
  Widget build(BuildContext context) {
    Future<void> saveAndPop() async {
      model.photoprismHttpBasicAuth.setEnabled(enabled);
      model.photoprismHttpBasicAuth.setUser(_httpBasicUserController.text);
      model.photoprismHttpBasicAuth
          .setPassword(_httpBasicPasswordController.text);
      model.photoprismRemoteConfigLoader.loadApplicationColor();
      await SettingsPage.emptyCache(context);
      Navigator.of(context).pop();
    }

    _httpBasicUserController.text = model.photoprismHttpBasicAuth.user;
    _httpBasicPasswordController.text = model.photoprismHttpBasicAuth.password;

    return AlertDialog(
      title: const Text('HTTP Authentication'),
      content: SingleChildScrollView(
          child: ListBody(
        children: <Widget>[
          SwitchListTile(
            title: const Text('HTTP Basic'),
            onChanged: (bool value) {
              setState(() {
                enabled = value;
              });
            },
            value: enabled,
          ),
          Visibility(
              visible: enabled,
              child: ListTile(
                  subtitle: const Text('user'),
                  title: TextField(
                    key: const ValueKey<String>('httpBasicUserTextField'),
                    controller: _httpBasicUserController,
                    decoration: const InputDecoration(hintText: 'user'),
                  ))),
          Visibility(
              visible: enabled,
              child: ListTile(
                  subtitle: const Text('password'),
                  title: TextField(
                    key: const ValueKey<String>('httpBasicPasswordTextField'),
                    controller: _httpBasicPasswordController,
                    decoration: const InputDecoration(hintText: 'password'),
                    obscureText: true,
                  ))),
        ],
      )),
      actions: <Widget>[
        FlatButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: const Text('Save'),
          onPressed: () => saveAndPop(),
        )
      ],
    );
  }
}
