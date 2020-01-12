import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

import '../api/albums.dart';
import '../api/photos.dart';
import '../common/hexcolor.dart';
import '../model/photoprism_model.dart';

class Settings extends StatelessWidget {
  final TextEditingController _urlTextFieldController = TextEditingController();
  final TextEditingController _uploadFolderTextFieldController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    var photorismModel = Provider.of<PhotoprismModel>(context);

    return Container(
        //width: double.maxFinite,
        child: ListView(
      children: <Widget>[
        ListTile(
          title: Text("Photoprism URL"),
          subtitle: Text(photorismModel.photoprismUrl),
          onTap: () {
            _settingsDisplayUrlDialog(context);
          },
        ),
        ListTile(
          title: Text("Empty cache"),
          onTap: () {
            emptyCache();
          },
        ),
        SwitchListTile(
          title: Text("Auto Upload"),
          secondary: const Icon(Icons.cloud_upload),
          value: Provider.of<PhotoprismModel>(context).autoUploadEnabled,
          onChanged: (bool newState) async {
            final PermissionHandler _permissionHandler = PermissionHandler();
            var result = await _permissionHandler
                .requestPermissions([PermissionGroup.storage]);

            if (result[PermissionGroup.storage] == PermissionStatus.granted) {
              print(newState);
              Provider.of<PhotoprismModel>(context)
                  .photoprismUploader
                  .setAutoUpload(newState);
            } else {
              print("Not authorized.");
            }
          },
        ),
        ListTile(
          title: Text("Upload folder"),
          subtitle: Text(photorismModel.autoUploadFolder),
          onTap: () {
            getUploadFolder(context);
          },
        ),
        ListTile(
          title: Text("Auto upload last time active"),
          subtitle: Text(photorismModel.autoUploadLastTimeActive),
        ),
        ListTile(
          title: Text(
              "Warning: Auto upload is still under development. It only works under Android at this moment. Not fully working. Auto upload will only upload photos to import folder in photoprism. Importing has to be done manually."),
        ),
      ],
    ));
  }

  void getUploadFolder(context) async {
    _settingsDisplayUploadFolderDialog(context);
  }

  _settingsDisplayUrlDialog(BuildContext context) async {
    var photorismModel = Provider.of<PhotoprismModel>(context);
    _urlTextFieldController.text = photorismModel.photoprismUrl;

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Enter Photoprism URL'),
            content: TextField(
              key: ValueKey("photoprismUrlTextField"),
              controller: _urlTextFieldController,
              cursorColor: HexColor(photorismModel.applicationColor),
              decoration:
                  InputDecoration(hintText: "https://demo.photoprism.org"),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                textColor: HexColor(photorismModel.applicationColor),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Save'),
                textColor: HexColor(photorismModel.applicationColor),
                onPressed: () {
                  setNewPhotoprismUrl(context, _urlTextFieldController.text);
                },
              )
            ],
          );
        });
  }

  _settingsDisplayUploadFolderDialog(BuildContext context) async {
    var photorismModel = Provider.of<PhotoprismModel>(context);
    _uploadFolderTextFieldController.text = photorismModel.autoUploadFolder;

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Enter upload folder path'),
            content: TextField(
              controller: _uploadFolderTextFieldController,
              cursorColor: HexColor(photorismModel.applicationColor),
              decoration:
                  InputDecoration(hintText: "/storage/emulated/0/DCIM/Camera"),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                textColor: HexColor(photorismModel.applicationColor),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Save'),
                textColor: HexColor(photorismModel.applicationColor),
                onPressed: () {
                  setNewUploadFolder(
                      context, _uploadFolderTextFieldController.text);
                },
              )
            ],
          );
        });
  }

  void setNewPhotoprismUrl(context, url) async {
    Navigator.of(context).pop();
    PhotoprismModel pmodel = Provider.of<PhotoprismModel>(context);
    await pmodel.photoprismCommonHelper.setPhotoprismUrl(url);
    pmodel.photoprismRemoteConfigLoader.loadApplicationColor();
    emptyCache();
    await Photos.loadPhotos(pmodel, pmodel.photoprismUrl, "");
    await Albums.loadAlbums(pmodel, pmodel.photoprismUrl);
  }

  void setNewUploadFolder(context, path) async {
    Navigator.of(context).pop();
    await Provider.of<PhotoprismModel>(context)
        .photoprismUploader
        .setUploadFolder(path);
  }

  void emptyCache() async {
    await DefaultCacheManager().emptyCache();
  }
}
