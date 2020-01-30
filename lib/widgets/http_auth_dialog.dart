import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photoprism/common/album_manager.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/pages/settings_page.dart';
import 'package:provider/provider.dart';

class HttpAuthDialog extends StatefulWidget {
  final BuildContext context;

  const HttpAuthDialog({Key key, this.context}) : super(key: key);

  _HttpAuthDialogState createState() => _HttpAuthDialogState(context);
}

class _HttpAuthDialogState extends State<HttpAuthDialog> {
  PhotoprismModel model;
  TextEditingController _httpBasicUserController;
  TextEditingController _httpBasicPasswordController;
  bool enabled;

  _HttpAuthDialogState(BuildContext context) {
    model = Provider.of<PhotoprismModel>(context);
    _httpBasicUserController = TextEditingController();
    _httpBasicPasswordController = TextEditingController();
    enabled = model.photoprismHttpBasicAuth.enabled;
  }

  @override
  Widget build(BuildContext context) {
    void saveAndPop() {
      model.photoprismHttpBasicAuth.setEnabled(enabled);
      model.photoprismHttpBasicAuth.setUser(_httpBasicUserController.text);
      model.photoprismHttpBasicAuth
          .setPassword(_httpBasicPasswordController.text);
      model.photoprismRemoteConfigLoader.loadApplicationColor();
      SettingsPage.emptyCache();
      PhotoManager.resetPhotos(context, null);
      AlbumManager.resetAlbums(context);
      Navigator.of(context).pop();
    }

    _httpBasicUserController.text = model.photoprismHttpBasicAuth.user;
    _httpBasicPasswordController.text = model.photoprismHttpBasicAuth.password;

    return AlertDialog(
      title: Text('HTTP Authentication'),
      content: SingleChildScrollView(
          child: ListBody(
        children: <Widget>[
          SwitchListTile(
            title: Text("HTTP Basic"),
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
                  subtitle: Text("user"),
                  title: TextField(
                    key: ValueKey("httpBasicUserTextField"),
                    controller: _httpBasicUserController,
                    decoration: InputDecoration(hintText: "user"),
                  ))),
          Visibility(
              visible: enabled,
              child: ListTile(
                  subtitle: Text("password"),
                  title: TextField(
                    key: ValueKey("httpBasicPasswordTextField"),
                    controller: _httpBasicPasswordController,
                    decoration: InputDecoration(hintText: "password"),
                    obscureText: true,
                  ))),
        ],
      )),
      actions: <Widget>[
        FlatButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: Text('Save'),
          onPressed: () => saveAndPop(),
        )
      ],
    );
  }
}
